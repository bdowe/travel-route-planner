-- +goose Up
-- Version itineraries by chat: each create_itinerary call appends a trip row
-- stamped with the conversation's chat_id, so My Trips can collapse to the
-- latest version per chat. is_admin gates viewing the full version history.
ALTER TABLE users ADD COLUMN is_admin boolean NOT NULL DEFAULT false;

ALTER TABLE trips ADD COLUMN chat_id text;  -- opaque conversation token; NULL for legacy/manual trips

CREATE INDEX idx_trips_user_chat ON trips(user_id, chat_id, created_at DESC);

-- +goose Down
DROP INDEX IF EXISTS idx_trips_user_chat;
ALTER TABLE trips DROP COLUMN IF EXISTS chat_id;
ALTER TABLE users DROP COLUMN IF EXISTS is_admin;
