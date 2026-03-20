-- ScriptFlow Phase 2: Database Migration
-- Run this in your Supabase SQL Editor

-- Add new columns
ALTER TABLE scans ADD COLUMN IF NOT EXISTS raw_ai_response jsonb;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS verified_data jsonb;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS status text DEFAULT 'processing';
ALTER TABLE scans ADD COLUMN IF NOT EXISTS uploaded_at timestamp DEFAULT now();
ALTER TABLE scans ADD COLUMN IF NOT EXISTS raw_image_url text;

-- Migrate existing data from old schema
UPDATE scans
SET raw_ai_response = extracted_data,
    status = CASE WHEN is_verified THEN 'verified' ELSE 'review_needed' END
WHERE raw_ai_response IS NULL AND extracted_data IS NOT NULL;

-- Drop old columns (run after verifying migration)
ALTER TABLE scans DROP COLUMN IF EXISTS extracted_data;
ALTER TABLE scans DROP COLUMN IF EXISTS is_verified;

-- Enable Realtime for the scans table
ALTER PUBLICATION supabase_realtime ADD TABLE scans;
