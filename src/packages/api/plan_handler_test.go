package main

import (
	"strings"
	"testing"

	"travel-route-planner/store"
)

func TestPersonalizedSystemPromptNilPrefs(t *testing.T) {
	if got := personalizedSystemPrompt("base", nil); got != "base" {
		t.Fatalf("prompt = %q, want base unchanged", got)
	}
}

func TestPersonalizedSystemPromptEmptyPrefs(t *testing.T) {
	if got := personalizedSystemPrompt("base", &store.TravelerPreference{}); got != "base" {
		t.Fatalf("prompt = %q, want base unchanged", got)
	}
}

func TestPersonalizedSystemPromptIncludesNotesAlone(t *testing.T) {
	p := &store.TravelerPreference{ProfileNotes: strPtr("- vegetarian\n- travels with kids")}
	got := personalizedSystemPrompt("base", p)
	if !strings.Contains(got, "Traveler profile notes (maintained by you):\n- vegetarian\n- travels with kids") {
		t.Fatalf("prompt missing notes block: %q", got)
	}
	if strings.Contains(got, "Traveler preferences —") {
		t.Fatalf("prompt should have no preferences line when fields are unset: %q", got)
	}
}

func TestPersonalizedSystemPromptCombinesFieldsAndNotes(t *testing.T) {
	p := &store.TravelerPreference{
		Budget:       strPtr("mid"),
		ProfileNotes: strPtr("- prefers boutique stays"),
	}
	got := personalizedSystemPrompt("base", p)
	if !strings.Contains(got, "budget: mid") {
		t.Fatalf("prompt missing budget: %q", got)
	}
	if !strings.Contains(got, "- prefers boutique stays") {
		t.Fatalf("prompt missing notes: %q", got)
	}
}

func TestPersonalizedSystemPromptIgnoresWhitespaceNotes(t *testing.T) {
	p := &store.TravelerPreference{ProfileNotes: strPtr("  \n ")}
	if got := personalizedSystemPrompt("base", p); got != "base" {
		t.Fatalf("prompt = %q, want base unchanged for blank notes", got)
	}
}

func TestNotesPreview(t *testing.T) {
	if got := notesPreview(nil); got != "" {
		t.Fatalf("preview = %q, want empty for nil", got)
	}
	if got := notesPreview(strPtr("short")); got != "short" {
		t.Fatalf("preview = %q", got)
	}
	long := strings.Repeat("é", 100)
	got := notesPreview(&long)
	if r := []rune(got); len(r) != 81 || !strings.HasSuffix(got, "…") {
		t.Fatalf("preview should be 80 runes + ellipsis, got %d runes: %q", len([]rune(got)), got)
	}
}
