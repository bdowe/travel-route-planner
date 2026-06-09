-- +goose Up
CREATE TABLE trip_segments (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id     uuid        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    mode        text        NOT NULL,            -- flight | train | bus | car | ferry | other
    origin      text,
    destination text,
    depart_date date,
    arrive_date date,
    provider    text,
    url         text,
    price_note  text,
    notes       text,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_trip_segments_trip_id ON trip_segments(trip_id);

CREATE TRIGGER trg_trip_segments_updated_at BEFORE UPDATE ON trip_segments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- +goose Down
DROP TABLE IF EXISTS trip_segments;
