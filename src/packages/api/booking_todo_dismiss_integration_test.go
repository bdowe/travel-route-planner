package main

import (
	"net/http"
	"strings"
	"testing"
)

// Dismissal (00077): the tombstone that makes "remove" real for derived rows.
// A deleted auto row came back on the next sync; a dismissed one stays synced
// but hidden — and the flag joins booked/auto/mode in the upsert's
// preservation-by-omission contract.

func dismissSyncPayload() []map[string]any {
	return []map[string]any{
		{"kind": "stay", "todo_key": "stay:bad ischl", "title": "Stay in Bad Ischl",
			"destination": "Bad Ischl", "position": 0},
		{"kind": "stay", "todo_key": "stay:naples", "title": "Stay in Naples",
			"destination": "Naples", "position": 1},
	}
}

func TestDismissSurvivesResyncAndRestores(t *testing.T) {
	resetDB(t)
	owner, token := createTestUser(t, "dismiss@example.com")
	trip := createTestTrip(t, owner.ID, 0)
	tripID := trip.ID.String()

	rows := decodeTodoList(t, doJSON(t, "PUT", "/api/v1/trips/"+tripID+"/booking-todos", token, dismissSyncPayload()))
	badIschl := rows[0]["id"].(string)
	if rows[0]["dismissed"] != false {
		t.Fatalf("new derived rows must start undismissed: %v", rows[0])
	}

	rec := doJSON(t, "PATCH", "/api/v1/trips/"+tripID+"/booking-todos/"+badIschl, token, map[string]any{"dismissed": true})
	if rec.Code != http.StatusOK || decode(t, rec)["dismissed"] != true {
		t.Fatalf("dismiss = %d: %s", rec.Code, rec.Body.String())
	}

	// THE point: a re-sync must not resurrect the row's visibility.
	rows = decodeTodoList(t, doJSON(t, "PUT", "/api/v1/trips/"+tripID+"/booking-todos", token, dismissSyncPayload()))
	if rows[0]["dismissed"] != true {
		t.Fatalf("re-sync resurrected a dismissed row: %v", rows[0])
	}
	if rows[1]["dismissed"] != false {
		t.Fatalf("dismissal leaked to a sibling row: %v", rows[1])
	}

	// Restore is the same lane with false.
	rec = doJSON(t, "PATCH", "/api/v1/trips/"+tripID+"/booking-todos/"+badIschl, token, map[string]any{"dismissed": false})
	if rec.Code != http.StatusOK || decode(t, rec)["dismissed"] != false {
		t.Fatalf("restore = %d: %s", rec.Code, rec.Body.String())
	}
}

func TestDismissLaneGuards(t *testing.T) {
	resetDB(t)
	owner, token := createTestUser(t, "dismiss-guards@example.com")
	trip := createTestTrip(t, owner.ID, 0)
	tripID := trip.ID.String()

	rows := decodeTodoList(t, doJSON(t, "PUT", "/api/v1/trips/"+tripID+"/booking-todos", token, dismissSyncPayload()))
	autoID := rows[0]["id"].(string)

	// Exclusive like the mode and city_label lanes.
	if rec := doJSON(t, "PATCH", "/api/v1/trips/"+tripID+"/booking-todos/"+autoID, token,
		map[string]any{"dismissed": true, "booked": true}); rec.Code != http.StatusBadRequest {
		t.Fatalf("combined fields = %d, want 400", rec.Code)
	}

	// A manual row is deleted, never dismissed: the auto-only WHERE 404s.
	rec := doJSON(t, "POST", "/api/v1/trips/"+tripID+"/booking-todos", token, map[string]any{
		"kind": "other", "todo_key": "custom:opera", "title": "Book the opera"})
	if rec.Code != http.StatusCreated {
		t.Fatalf("create manual = %d: %s", rec.Code, rec.Body.String())
	}
	manualID := decode(t, rec)["id"].(string)
	if rec := doJSON(t, "PATCH", "/api/v1/trips/"+tripID+"/booking-todos/"+manualID, token,
		map[string]any{"dismissed": true}); rec.Code != http.StatusNotFound {
		t.Fatalf("dismiss manual = %d, want 404", rec.Code)
	}
}

// The agent's remove_booking_todo dismisses derived rows instead of refusing —
// "we're staying with my cousin" becomes one call — while manual rows keep the
// existing delete (and its stakes ladder).
func TestRemoveToolDismissesAutoRows(t *testing.T) {
	resetDB(t)
	owner, token := createTestUser(t, "dismiss-tool@example.com")
	trip := createTestTrip(t, owner.ID, 0)
	tripID := trip.ID.String()

	rows := decodeTodoList(t, doJSON(t, "PUT", "/api/v1/trips/"+tripID+"/booking-todos", token, dismissSyncPayload()))
	autoID := rows[0]["id"].(string)

	s, _ := testPlanSession(true, owner.ID)
	msg, isErr := runRemoveBookingTodoTool(s, []byte(`{"trip_id":"`+tripID+`","todo_id":"`+autoID+`"}`))
	if isErr {
		t.Fatalf("tool on auto row errored: %s", msg)
	}
	for _, want := range []string{"Stay in Bad Ischl", "no booking", "restore"} {
		if !strings.Contains(strings.ToLower(msg), strings.ToLower(want)) {
			t.Errorf("result missing %q: %s", want, msg)
		}
	}
	rows = decodeTodoList(t, doJSON(t, "PUT", "/api/v1/trips/"+tripID+"/booking-todos", token, dismissSyncPayload()))
	if rows[0]["dismissed"] != true {
		t.Fatalf("tool did not dismiss: %v", rows[0])
	}

	// get_trip tells the model the slot needs no booking, so it stops nagging.
	tripMsg, _ := runGetTripTool(s.ctx, true, owner.ID, &trip.ID, []byte(`{"trip_id":"`+tripID+`"}`))
	if !strings.Contains(tripMsg, "removed by traveler — no booking needed") {
		t.Fatalf("get_trip does not mark the dismissed row:\n%s", tripMsg)
	}
}
