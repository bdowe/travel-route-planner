-- +goose Up
-- Flesh out the baseline trips skeleton and add its ordered itinerary items.
ALTER TABLE trips
    ADD COLUMN title      text NOT NULL DEFAULT '',
    ADD COLUMN start_date date,
    ADD COLUMN end_date   date,
    ADD COLUMN status     text NOT NULL DEFAULT 'draft';

CREATE TABLE itinerary_items (
    id         uuid             PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id    uuid             NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    position   int              NOT NULL,
    name       text             NOT NULL,
    place_id   text,
    address    text,
    latitude   double precision NOT NULL,
    longitude  double precision NOT NULL,
    created_at timestamptz      NOT NULL DEFAULT now()
);

CREATE INDEX idx_itinerary_items_trip_position ON itinerary_items(trip_id, position);

-- +goose Down
DROP TABLE IF EXISTS itinerary_items;
ALTER TABLE trips
    DROP COLUMN IF EXISTS title,
    DROP COLUMN IF EXISTS start_date,
    DROP COLUMN IF EXISTS end_date,
    DROP COLUMN IF EXISTS status;
