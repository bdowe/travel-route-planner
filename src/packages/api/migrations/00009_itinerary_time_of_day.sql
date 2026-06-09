-- +goose Up
-- Part of day (morning | afternoon | evening) the AI agent assigns to each
-- itinerary place so a day reads as a loose schedule. Nullable; legacy/manual
-- items leave it unset.
ALTER TABLE itinerary_items ADD COLUMN time_of_day text;

-- +goose Down
ALTER TABLE itinerary_items DROP COLUMN IF EXISTS time_of_day;
