-- name: CreateTrip :one
INSERT INTO trips (user_id, title, status)
VALUES ($1, $2, $3)
RETURNING *;

-- name: CreateItineraryItem :one
INSERT INTO itinerary_items (trip_id, position, name, place_id, address, latitude, longitude, category)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;

-- name: ListTripsByOwner :many
SELECT * FROM trips WHERE user_id = $1 ORDER BY created_at DESC;

-- name: GetTripByIDAndOwner :one
SELECT * FROM trips WHERE id = $1 AND user_id = $2;

-- name: GetItineraryItemsByTrip :many
SELECT * FROM itinerary_items WHERE trip_id = $1 ORDER BY position ASC;

-- name: UpdateTrip :one
UPDATE trips
SET title      = COALESCE(sqlc.narg('title'), title),
    start_date = COALESCE(sqlc.narg('start_date'), start_date),
    end_date   = COALESCE(sqlc.narg('end_date'), end_date),
    status     = COALESCE(sqlc.narg('status'), status)
WHERE id = sqlc.arg('id') AND user_id = sqlc.arg('user_id')
RETURNING *;

-- name: DeleteTrip :execrows
DELETE FROM trips WHERE id = $1 AND user_id = $2;
