-- +goose Up
-- The traveler's gender, for personalization that genuinely depends on it —
-- what-to-wear suggestions, safety-relevant advice. Deliberately nullable
-- with no default: unset means "not stated", which is a first-class state.
-- The traveler sets it in the signup quiz or Travel profile and can CLEAR it
-- there too (the clear_gender flag in UpsertPreferences — the home_airport
-- pattern, extended to an enum field for the first time because a stored
-- gender the traveler cannot remove is a different kind of wrong than an
-- unremovable pace). The agent's save_preferences may set it only from the
-- traveler's own words and can never clear it; the profile distiller never
-- mines it from conversation at all.
ALTER TABLE traveler_preferences ADD COLUMN gender text; -- male | female

-- +goose Down
ALTER TABLE traveler_preferences DROP COLUMN IF EXISTS gender;
