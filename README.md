# ScriptFlow

Clinical Register Digitizer - AI-powered handwritten document extraction system.

## Architecture

```
ScriptFlow/
├── apps/
│   ├── mobile/          # Flutter app (document scanning)
│   └── web/             # React dashboard (Vite + Tailwind)
├── backend/             # FastAPI server (Gemini AI + Supabase)
├── infrastructure/      # Dockerfile + SQL migrations
├── packages/            # Shared packages (future)
└── docker-compose.yml
```

## Quick Start

### Backend
```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Fill in your keys
uvicorn main:app --reload
```

### Web Dashboard
```bash
cd apps/web
npm install
cp .env.example .env  # Fill in your keys
npm run dev
```

### Mobile App
```bash
cd apps/mobile
flutter pub get
flutter run
```

### Docker (Full Stack)
```bash
docker-compose up
```

## Database Migration

Run `infrastructure/migration.sql` in your Supabase SQL Editor before starting the upgraded backend.

## Environment Variables

See `.env.example` in the project root for all required variables.
