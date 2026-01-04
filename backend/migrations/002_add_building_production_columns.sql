-- Migration: Add production tracking columns to buildings table
-- Date: 2026-01-04

ALTER TABLE buildings
ADD COLUMN IF NOT EXISTS is_producing boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS ready_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS producing_qty bigint NULL;
