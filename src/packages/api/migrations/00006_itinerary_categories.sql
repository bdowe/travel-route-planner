-- +goose Up
-- Tag itinerary items with a category so the agent's mix of attractions and
-- dining is legible in the UI. Nullable; existing rows stay un-tagged.
-- Allowed set ('attraction' | 'restaurant') is enforced in the application,
-- not the DB, so future categories don't need a migration.
ALTER TABLE itinerary_items ADD COLUMN category text;

-- +goose Down
ALTER TABLE itinerary_items DROP COLUMN IF EXISTS category;
