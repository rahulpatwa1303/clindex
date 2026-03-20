from google import genai
from google.genai import types
from PIL import Image

# FIX: Pass the string directly (or set an environment variable named GEMINI_API_KEY)
client = genai.Client(api_key="AIzaSyARVxgKojuuneQgBpCtLDXdP_POjyXbFFo")

img = Image.open("test.jpeg")

prompt = """
You are an expert transcriber for handwritten clinical registers. 
Analyze this image and extract the data into a structured JSON format.

### PAGE LAYOUT ANALYSIS:
1. **Header Section**: Look at the very top of the page. extract the "Date" and any "Summary" numbers (like Total Cash, GPay, etc).
2. **Main Table**: The page is a table with 5 columns.
   - **Col 1 (ID):** A number, often circled or with a bracket (e.g., "1)", "4307").
   - **Col 2 (Name):** The patient's full name.
   - **Col 3 (Treatment):** The medical procedure (e.g., "Dressing", "Scaling", "Root Canal").
   - **Col 4 (Doctor):** The doctor or staff name (e.g., "Dr. Chaitali", "Gayatri").
   - **Col 5 (Amount):** The fee. Ignore symbols like '/-'. specificy if it says 'Gp' (GPay) or 'Cash'.

### EXTRACTION RULES:
- Transcribe row by row.
- If a column is blank (like "Treatment" or "Doctor"), use null.
- If the "Amount" column has "Gp" or "Online", set "payment_mode" to "Online", otherwise "Cash".
- **Do not invent data.** If you can't read it, put "illegible".

### JSON OUTPUT FORMAT:
Return ONLY this JSON structure:
{
  "page_header": {
    "date": "DD/MM/YY",
    "daily_summary": {
       "online_total": number,
       "cash_total": number,
       "grand_total": number
    }
  },
  "records": [
    {
      "serial_no": "string",
      "patient_name": "string",
      "treatment": "string",
      "doctor_name": "string",
      "amount": number,
      "payment_mode": "string (Cash/Online/Unknown)"
    }
  ]
}
"""


response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents=[
        prompt,
        img  # The client usually handles PIL images directly now
    ],
    config=types.GenerateContentConfig(
        response_mime_type="application/json" # This forces valid JSON output
    )
)

print(response.text)

# print("Fetching available models...")
# try:
#     # In the new SDK, we just iterate and print the name
#     for m in client.models.list():
#         # Filter for models that likely support content generation
#         if "gemini" in m.name:
#             print(f"Found: {m.name}")
            
# except Exception as e:
#     print(f"Error: {e}")