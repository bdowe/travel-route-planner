-- +goose Up
ALTER TABLE traveler_preferences ADD COLUMN profile_notes text; -- AI-maintained bullet profile, capped at 2000 chars

-- +goose Down
ALTER TABLE traveler_preferences DROP COLUMN IF EXISTS profile_notes;
