package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"

	"travel-route-planner/store"
)

// specs/traveler-gender (00076): optional, stated-only, and the one enum
// preference a traveler can CLEAR, not just change.

func getPrefs(t *testing.T, token string) map[string]any {
	t.Helper()
	rec := doJSON(t, "GET", "/api/v1/preferences", token, nil)
	if rec.Code != http.StatusOK {
		t.Fatalf("get preferences = %d", rec.Code)
	}
	var m map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &m); err != nil {
		t.Fatalf("prefs decode: %v", err)
	}
	return m
}

func TestTravelerGenderSetChangeClear(t *testing.T) {
	resetDB(t)
	_, token := createTestUser(t, "gender@example.com")

	if rec := doJSON(t, "PUT", "/api/v1/preferences", token, map[string]any{"gender": "male"}); rec.Code != http.StatusOK {
		t.Fatalf("set = %d: %s", rec.Code, rec.Body.String())
	}
	if g := getPrefs(t, token)["gender"]; g != "male" {
		t.Fatalf("gender after set = %v", g)
	}

	if rec := doJSON(t, "PUT", "/api/v1/preferences", token, map[string]any{"gender": "Female"}); rec.Code != http.StatusOK {
		t.Fatalf("change = %d", rec.Code)
	}
	if g := getPrefs(t, token)["gender"]; g != "female" {
		t.Fatalf("gender after change = %v (input normalizes like every choice field)", g)
	}

	// A save that omits the field keeps it — the COALESCE contract.
	if rec := doJSON(t, "PUT", "/api/v1/preferences", token, map[string]any{"pace": "relaxed"}); rec.Code != http.StatusOK {
		t.Fatalf("unrelated save = %d", rec.Code)
	}
	if g := getPrefs(t, token)["gender"]; g != "female" {
		t.Fatalf("gender after unrelated save = %v, want kept", g)
	}

	// "" is an explicit clear — the home_airport pattern, extended to an enum
	// field for the first time because a stored gender the traveler cannot
	// remove is not acceptable (00076).
	if rec := doJSON(t, "PUT", "/api/v1/preferences", token, map[string]any{"gender": ""}); rec.Code != http.StatusOK {
		t.Fatalf("clear = %d", rec.Code)
	}
	if g := getPrefs(t, token)["gender"]; g != nil {
		t.Fatalf("gender after clear = %v, want null", g)
	}
}

func TestTravelerGenderRejectsUnknownValues(t *testing.T) {
	resetDB(t)
	_, token := createTestUser(t, "gender-bad@example.com")
	rec := doJSON(t, "PUT", "/api/v1/preferences", token, map[string]any{"gender": "attack_helicopter"})
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("unknown value = %d, want 400", rec.Code)
	}
	if g := getPrefs(t, token)["gender"]; g != nil {
		t.Fatalf("a rejected value wrote %v", g)
	}
}

// The agent may SET gender from the traveler's own words but can never clear
// it — the same only-the-user-empties rule as home_airport and notes.
func TestSavePreferencesToolGenderIsSetOnly(t *testing.T) {
	resetDB(t)
	user, token := createTestUser(t, "gender-tool@example.com")

	s, _ := testPlanSession(true, user.ID)
	if msg, isErr := runSavePreferencesTool(s, []byte(`{"gender":"female"}`)); isErr {
		t.Fatalf("tool set errored: %s", msg)
	}
	if g := getPrefs(t, token)["gender"]; g != "female" {
		t.Fatalf("gender after tool set = %v", g)
	}
	if msg, isErr := runSavePreferencesTool(s, []byte(`{"gender":""}`)); isErr {
		t.Fatalf("tool empty errored: %s", msg)
	}
	if g := getPrefs(t, token)["gender"]; g != "female" {
		t.Fatalf("an agent empty-string cleared gender (= %v); only the traveler's PUT may", g)
	}
}

// The personalization block lists gender only when stated, like every field.
func TestPersonalizedPromptCarriesStatedGender(t *testing.T) {
	female := "female"
	withPrefs := personalizedSystemPrompt("BASE", &store.TravelerPreference{Gender: &female})
	if !strings.Contains(withPrefs, "gender: female") {
		t.Fatalf("stated gender missing from personalization:\n%s", withPrefs)
	}
	without := personalizedSystemPrompt("BASE", &store.TravelerPreference{})
	if strings.Contains(without, "gender") {
		t.Fatalf("unset gender must not appear:\n%s", without)
	}
}
