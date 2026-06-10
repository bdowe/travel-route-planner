package main

import (
	"encoding/json"
	"net/http"
	"strings"

	"travel-route-planner/store"
)

type AddItineraryItemRequest struct {
	Name      string   `json:"name"`
	PlaceID   *string  `json:"place_id"`
	Address   *string  `json:"address"`
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
	Category  *string  `json:"category"`
	TimeOfDay *string  `json:"time_of_day"`
	City      *string  `json:"city"`
	Day       *int     `json:"day"`
}

// insertPositionForDay places a new item at the end of its day: just after the
// last item whose day is set and <= the requested day. Unscheduled items (nil
// day) don't advance the cursor, so a day-tagged insert lands before the
// trailing unscheduled block. A nil requested day appends to the very end.
func insertPositionForDay(items []store.ItineraryItem, day *int) int {
	if day == nil {
		return len(items)
	}
	pos := 0
	for i, it := range items {
		if it.Day != nil && int(*it.Day) <= *day {
			pos = i + 1
		}
	}
	return pos
}

func addItineraryItemHandler(w http.ResponseWriter, r *http.Request) {
	tripID, ok := ownedTrip(w, r)
	if !ok {
		return
	}
	var req AddItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	name := strings.TrimSpace(req.Name)
	if name == "" {
		writeJSONError(w, http.StatusBadRequest, "name is required")
		return
	}
	var category *string
	if req.Category != nil {
		c := strings.ToLower(strings.TrimSpace(*req.Category))
		if !allowedItemCategories[c] {
			writeJSONError(w, http.StatusBadRequest, "category must be 'attraction' or 'restaurant'")
			return
		}
		category = &c
	}
	var timeOfDay *string
	if req.TimeOfDay != nil {
		t := strings.ToLower(strings.TrimSpace(*req.TimeOfDay))
		if !allowedTimesOfDay[t] {
			writeJSONError(w, http.StatusBadRequest, "time_of_day must be 'morning', 'afternoon' or 'evening'")
			return
		}
		timeOfDay = &t
	}
	var day *int32
	if req.Day != nil {
		if *req.Day < 1 {
			writeJSONError(w, http.StatusBadRequest, "day must be >= 1")
			return
		}
		d := int32(*req.Day)
		day = &d
	}
	var city *string
	if req.City != nil {
		if c := strings.TrimSpace(*req.City); c != "" {
			city = &c
		}
	}
	// Columns are NOT NULL; (0,0) is the established "no location" sentinel the
	// app already excludes from the map and travel times.
	var lat, lng float64
	if req.Latitude != nil && req.Longitude != nil {
		lat, lng = *req.Latitude, *req.Longitude
	}

	ctx := r.Context()
	tx, err := dbPool.Begin(ctx)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not save place")
		return
	}
	defer tx.Rollback(ctx)
	q := store.New(tx)

	items, err := q.GetItineraryItemsByTrip(ctx, tripID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not load itinerary")
		return
	}
	pos := insertPositionForDay(items, req.Day)
	if err := q.ShiftItineraryItemPositions(ctx, store.ShiftItineraryItemPositionsParams{
		TripID: tripID, Position: int32(pos),
	}); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not save place")
		return
	}
	if _, err := q.CreateItineraryItem(ctx, store.CreateItineraryItemParams{
		TripID:    tripID,
		Position:  int32(pos),
		Name:      name,
		PlaceID:   req.PlaceID,
		Address:   req.Address,
		Latitude:  lat,
		Longitude: lng,
		Category:  category,
		TimeOfDay: timeOfDay,
		City:      city,
		Day:       day,
	}); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not save place")
		return
	}
	if err := q.TouchTrip(ctx, tripID); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not save place")
		return
	}
	if err := tx.Commit(ctx); err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not save place")
		return
	}

	user, _ := userFromContext(ctx)
	qr := store.New(dbPool)
	trip, err := qr.GetTripByIDAndOwner(ctx, store.GetTripByIDAndOwnerParams{ID: tripID, UserID: user.ID})
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not load trip")
		return
	}
	updated, err := qr.GetItineraryItemsByTrip(ctx, tripID)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "could not load itinerary")
		return
	}
	writeJSON(w, http.StatusCreated, toTripResponse(trip, updated, nil, nil, nil))
}
