import os
import io
import json
import uuid
import urllib.request
from datetime import date, timedelta
from typing import Optional

import jwt as pyjwt
from jwt import PyJWKClient
from fastapi import FastAPI, UploadFile, File, HTTPException, Query, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from supabase import create_client, Client
from google import genai
from google.genai import types
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

# --- CONFIGURATION ---
SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]
JWKS_CLIENT = PyJWKClient(f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json")
ALLOWED_ORIGINS = [
    o.strip()
    for o in os.environ.get("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173").split(",")
    if o.strip()
]

app = FastAPI(title="ScriptFlow API", version="2.0.0")

# --- RATE LIMITING ---
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

# --- INITIALIZE SERVICES ---
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
ai_client = genai.Client(api_key=GEMINI_API_KEY)

# --- AUTH ---
security = HTTPBearer()


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """Validate Supabase user JWT via JWKS (supports ES256 and HS256)."""
    token = credentials.credentials
    try:
        signing_key = JWKS_CLIENT.get_signing_key_from_jwt(token)
        payload = pyjwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256", "HS256"],
            options={"verify_aud": False},
        )
        return payload
    except pyjwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Session expired. Please log in again.")
    except Exception as e:
        print(f"[verify_token] {type(e).__name__}: {e}")
        raise HTTPException(status_code=401, detail="Invalid token.")


def _run_extraction(image_pil: Image.Image) -> dict:
    """Run Gemini extraction and return parsed JSON."""
    response = ai_client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[EXTRACTION_PROMPT, image_pil],
        config=types.GenerateContentConfig(response_mime_type="application/json"),
    )
    return json.loads(response.text)


def _storage_path_from_url(url: str) -> Optional[str]:
    """Extract the storage object path from a Supabase public URL."""
    bucket = "handwriting-uploads/"
    idx = url.find(bucket)
    if idx == -1:
        return None
    return url[idx + len(bucket):]


EXTRACTION_PROMPT = """
Analyze this handwritten clinical register image. Extract all data into valid JSON.

IMPORTANT: For EVERY field value you extract, also return its bounding box coordinates
using the `box_2d` format: [y_min, x_min, y_max, x_max] where coordinates are
normalized to 0-1000 scale (relative to image dimensions).

Return this exact structure:
{
  "header": {
    "date": { "value": "DD/MM/YY", "confidence": 0.0, "box_2d": [y1, x1, y2, x2] },
    "summary": {
      "cash": { "value": 0, "confidence": 0.0, "box_2d": [y1, x1, y2, x2] },
      "online": { "value": 0, "confidence": 0.0, "box_2d": [y1, x1, y2, x2] }
    }
  },
  "records": [
    {
      "patient_name": { "value": "string", "confidence": 0.0, "box_2d": [y1, x1, y2, x2] },
      "treatment": { "value": "string", "confidence": 0.0, "box_2d": [y1, x1, y2, x2] },
      "amount": { "value": 0, "confidence": 0.0, "box_2d": [y1, x1, y2, x2] },
      "mode": { "value": "Cash or Online", "confidence": 0.0, "box_2d": [y1, x1, y2, x2] }
    }
  ]
}

Rules:
- confidence is 0.0-1.0 indicating how certain you are of the reading
- box_2d coordinates are [y_min, x_min, y_max, x_max] normalized to 0-1000
- Extract ALL records visible in the register
- If a field is illegible, set confidence below 0.5 and use your best guess
"""


@app.get("/")
def home():
    return {"message": "ScriptFlow API is running", "version": "2.0.0"}


@app.post("/scan")
@limiter.limit("10/minute")
async def scan_document(
    request: Request,
    file: UploadFile = File(...),
    raw_file: Optional[UploadFile] = File(None),
    _user: dict = Depends(verify_token),
):
    """Upload processed (and optionally raw) image, extract data with AI."""
    contents = await file.read()
    image_pil = Image.open(io.BytesIO(contents))

    file_ext = file.filename.split(".")[-1] if file.filename else "jpg"
    scan_id = str(uuid.uuid4())
    file_path = f"scans/{scan_id}.{file_ext}"

    supabase.storage.from_("handwriting-uploads").upload(
        file_path, contents, {"content-type": file.content_type}
    )
    public_url = supabase.storage.from_("handwriting-uploads").get_public_url(file_path)

    raw_image_url = None
    if raw_file is not None:
        raw_contents = await raw_file.read()
        raw_ext = raw_file.filename.split(".")[-1] if raw_file.filename else "jpg"
        raw_path = f"scans/{scan_id}_raw.{raw_ext}"
        supabase.storage.from_("handwriting-uploads").upload(
            raw_path, raw_contents, {"content-type": raw_file.content_type}
        )
        raw_image_url = supabase.storage.from_("handwriting-uploads").get_public_url(raw_path)

    # Save record immediately so a failure still leaves a retryable entry
    db_response = supabase.table("scans").insert({
        "image_url": public_url,
        "raw_image_url": raw_image_url,
        "raw_ai_response": None,
        "verified_data": None,
        "status": "processing",
    }).execute()
    record_id = db_response.data[0]["id"]

    try:
        extracted_json = _run_extraction(image_pil)
        supabase.table("scans").update({
            "raw_ai_response": extracted_json,
            "status": "review_needed",
        }).eq("id", record_id).execute()
        return {
            "status": "success",
            "scan_id": record_id,
            "data": extracted_json,
            "image_url": public_url,
            "raw_image_url": raw_image_url,
        }
    except Exception as e:
        print(f"[scan_document] AI extraction failed for {record_id}: {e}")
        supabase.table("scans").update({"status": "failed"}).eq("id", record_id).execute()
        return {
            "status": "failed",
            "scan_id": record_id,
            "image_url": public_url,
            "raw_image_url": raw_image_url,
        }


@app.post("/scan/{scan_id}/retry")
@limiter.limit("10/minute")
async def retry_scan(
    request: Request,
    scan_id: str,
    _user: dict = Depends(verify_token),
):
    """Re-run AI extraction on a previously failed scan."""
    try:
        scan = supabase.table("scans").select("*").eq("id", scan_id).single().execute().data
    except Exception:
        raise HTTPException(status_code=404, detail="Scan not found")

    if scan.get("status") not in ("failed", "review_needed"):
        raise HTTPException(status_code=400, detail="Only failed or review_needed scans can be retried")

    image_url = scan.get("image_url")
    if not image_url:
        raise HTTPException(status_code=400, detail="Scan has no image to retry")

    # Download image from storage
    try:
        with urllib.request.urlopen(image_url) as resp:
            image_pil = Image.open(io.BytesIO(resp.read()))
            image_pil.load()  # ensure fully read before closing the response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch image: {e}")

    # Mark as processing while we work
    supabase.table("scans").update({"status": "processing"}).eq("id", scan_id).execute()

    try:
        extracted_json = _run_extraction(image_pil)
        supabase.table("scans").update({
            "raw_ai_response": extracted_json,
            "verified_data": None,
            "status": "review_needed",
        }).eq("id", scan_id).execute()
        return {"status": "success", "scan_id": scan_id, "data": extracted_json}
    except Exception as e:
        print(f"[retry_scan] AI extraction failed for {scan_id}: {e}")
        supabase.table("scans").update({"status": "failed"}).eq("id", scan_id).execute()
        raise HTTPException(status_code=500, detail="Extraction failed. Please try again.")


@app.delete("/scan/{scan_id}")
@limiter.limit("20/minute")
async def delete_scan(
    request: Request,
    scan_id: str,
    _user: dict = Depends(verify_token),
):
    """Delete a scan and its associated storage files."""
    try:
        scan = supabase.table("scans").select("image_url, raw_image_url").eq("id", scan_id).single().execute().data
    except Exception:
        raise HTTPException(status_code=404, detail="Scan not found")

    # Delete storage files (best-effort — don't fail if already gone)
    paths_to_delete = []
    for url in [scan.get("image_url"), scan.get("raw_image_url")]:
        if url:
            path = _storage_path_from_url(url)
            if path:
                paths_to_delete.append(path)
    if paths_to_delete:
        try:
            supabase.storage.from_("handwriting-uploads").remove(paths_to_delete)
        except Exception as e:
            print(f"[delete_scan] Storage cleanup warning for {scan_id}: {e}")

    supabase.table("scans").delete().eq("id", scan_id).execute()
    return {"status": "success", "scan_id": scan_id}


@app.get("/scans")
@limiter.limit("30/minute")
async def list_scans(
    request: Request,
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None),
    from_date: Optional[str] = Query(None, alias="from"),
    to_date: Optional[str] = Query(None, alias="to"),
    _user: dict = Depends(verify_token),
):
    """Paginated list of all scans, optionally filtered by status and date range."""
    try:
        query = supabase.table("scans").select(
            "id, created_at, image_url, status, uploaded_at",
            count="exact",
        )
        if status:
            query = query.eq("status", status)
        if from_date:
            query = query.gte("created_at", from_date)
        if to_date:
            # Add one day so the "to" date is fully inclusive (covers the whole day)
            to_inclusive = (date.fromisoformat(to_date) + timedelta(days=1)).isoformat()
            query = query.lt("created_at", to_inclusive)
        query = query.order("created_at", desc=True).range(offset, offset + limit - 1)
        response = query.execute()

        return {
            "data": response.data,
            "total": response.count,
            "offset": offset,
            "limit": limit,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/scans/pending")
@limiter.limit("30/minute")
async def get_pending_scans(
    request: Request,
    _user: dict = Depends(verify_token),
):
    """Fetch all scans needing review."""
    try:
        response = (
            supabase.table("scans")
            .select("id, created_at, image_url, status, raw_ai_response")
            .eq("status", "review_needed")
            .order("created_at", desc=True)
            .execute()
        )
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/scan/{scan_id}")
@limiter.limit("30/minute")
async def get_scan(
    request: Request,
    scan_id: str,
    _user: dict = Depends(verify_token),
):
    """Get a single scan with full data including coordinates."""
    try:
        response = (
            supabase.table("scans")
            .select("*")
            .eq("id", scan_id)
            .single()
            .execute()
        )
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.patch("/scan/{scan_id}")
@limiter.limit("20/minute")
async def update_scan(
    request: Request,
    scan_id: str,
    body: dict,
    _user: dict = Depends(verify_token),
):
    """Update verified_data and set status to verified."""
    try:
        update_data = {}
        if "verified_data" in body:
            update_data["verified_data"] = body["verified_data"]
        if "status" in body:
            update_data["status"] = body["status"]
        else:
            update_data["status"] = "verified"

        response = (
            supabase.table("scans")
            .update(update_data)
            .eq("id", scan_id)
            .execute()
        )

        if not response.data:
            raise HTTPException(status_code=404, detail="Scan not found")

        return {"status": "success", "data": response.data[0]}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
