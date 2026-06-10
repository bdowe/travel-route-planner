package main

import (
	"strings"
	"testing"
)

func TestBuildDistillationTranscriptLabelsRoles(t *testing.T) {
	got := buildDistillationTranscript([]PlanChatMessage{
		{Role: "user", Content: "I'm vegetarian"},
		{Role: "assistant", Content: "Noted!"},
	}, 40, 30000)
	want := "Traveler: I'm vegetarian\n\nAgent: Noted!"
	if got != want {
		t.Fatalf("transcript = %q, want %q", got, want)
	}
}

func TestBuildDistillationTranscriptSkipsBlankMessages(t *testing.T) {
	got := buildDistillationTranscript([]PlanChatMessage{
		{Role: "user", Content: "   "},
		{Role: "user", Content: "hello"},
	}, 40, 30000)
	if got != "Traveler: hello" {
		t.Fatalf("transcript = %q", got)
	}
}

func TestBuildDistillationTranscriptKeepsNewestMessages(t *testing.T) {
	msgs := []PlanChatMessage{
		{Role: "user", Content: "oldest"},
		{Role: "user", Content: "middle"},
		{Role: "user", Content: "newest"},
	}
	got := buildDistillationTranscript(msgs, 2, 30000)
	if strings.Contains(got, "oldest") {
		t.Fatalf("transcript should drop oldest beyond maxMsgs: %q", got)
	}
	if !strings.Contains(got, "middle") || !strings.Contains(got, "newest") {
		t.Fatalf("transcript should keep the newest messages: %q", got)
	}
}

func TestBuildDistillationTranscriptTrimsOldestToCharCap(t *testing.T) {
	msgs := []PlanChatMessage{
		{Role: "user", Content: strings.Repeat("x", 100)},
		{Role: "user", Content: "recent"},
	}
	got := buildDistillationTranscript(msgs, 40, 50)
	if strings.Contains(got, "xxx") {
		t.Fatalf("oldest oversized message should be trimmed: %q", got)
	}
	if got != "Traveler: recent" {
		t.Fatalf("transcript = %q", got)
	}
}

func TestBuildDistillationTranscriptEmpty(t *testing.T) {
	if got := buildDistillationTranscript(nil, 40, 30000); got != "" {
		t.Fatalf("transcript = %q, want empty", got)
	}
}
