-- name: CreateSegment :one
INSERT INTO trip_segments (trip_id, mode, origin, destination, depart_date, arrive_date, provider, url, price_note, notes)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING *;

-- name: ListSegmentsByTrip :many
SELECT * FROM trip_segments WHERE trip_id = $1 ORDER BY depart_date ASC NULLS LAST, created_at ASC;

-- name: DeleteSegment :execrows
DELETE FROM trip_segments WHERE id = $1 AND trip_id = $2;
