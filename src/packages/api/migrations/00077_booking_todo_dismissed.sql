-- +goose Up
-- A derived checklist row the trip does not need (specs/dismiss-derived-
-- bookings): the traveler staying with family has no accommodation to book,
-- but "Stay in Bad Ischl" is auto-derived, so deleting it only lasted until
-- the next sync recreated it. Dismissal is the tombstone that survives:
-- the flag joins booked/auto/mode in the upsert's preservation contract
-- (absent from the INSERT column list, so new rows take the DEFAULT; absent
-- from DO UPDATE, so a re-sync never resurrects the row's visibility).
-- Dismissed rows stay synced — dates and labels keep refreshing — but the
-- client hides them from the to-book view, progress counts skip them, the
-- next-step nudges skip them, and the agent sees them marked so it stops
-- suggesting the booking. Restoring is one PATCH back; a dismissed row whose
-- slot leaves the itinerary is deleted by the existing stale ladder like any
-- other auto row.
ALTER TABLE booking_todos ADD COLUMN dismissed boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE booking_todos DROP COLUMN IF EXISTS dismissed;
