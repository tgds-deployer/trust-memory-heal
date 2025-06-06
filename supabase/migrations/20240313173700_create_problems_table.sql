-- Migration: Create Problems Table (20240313173700)

-- 🟢 Ensure problems table exists (skip if already created in prior migration)
CREATE TABLE IF NOT EXISTS problems (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  repository_contents JSONB,
  status TEXT DEFAULT 'Unsolved',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 🟢 Add new columns to problems table
ALTER TABLE problems
  ADD COLUMN version INTEGER,
  ADD COLUMN solution JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN prompt JSONB NOT NULL DEFAULT '{}';

-- 🟢 Update repository_contents to use TEXT instead of JSONB
ALTER TABLE problems 
  ALTER COLUMN repository_contents TYPE TEXT USING repository_contents::text;

-- 🟢 Add enum type for status
CREATE TYPE problem_status AS ENUM ('Solved', 'Unsolved');

-- 🟢 Normalize existing values before casting
UPDATE problems 
  SET status = 'Unsolved'
  WHERE status NOT IN ('Solved', 'Unsolved');

-- 🟢 Drop default before casting
ALTER TABLE problems 
  ALTER COLUMN status DROP DEFAULT;

-- 🟢 Cast status column to enum
ALTER TABLE problems 
  ALTER COLUMN status TYPE problem_status USING status::problem_status;

-- 🟢 Reapply default with enum type
ALTER TABLE problems 
  ALTER COLUMN status SET DEFAULT 'Unsolved';


-- === Down Migration ===

-- Drop default that still references enum type
ALTER TABLE problems 
  ALTER COLUMN status DROP DEFAULT;

-- Revert status column to TEXT
ALTER TABLE problems 
  ALTER COLUMN status TYPE TEXT;

-- Drop enum type
DROP TYPE IF EXISTS problem_status;

-- Revert repository_contents column to JSONB
ALTER TABLE problems 
  ALTER COLUMN repository_contents TYPE JSONB USING repository_contents::jsonb;

-- Remove added columns
ALTER TABLE problems
  DROP COLUMN version,
  DROP COLUMN solution,
  DROP COLUMN prompt;

