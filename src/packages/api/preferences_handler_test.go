package main

import (
	"strings"
	"testing"
)

func strPtr(s string) *string { return &s }

func TestNormalizeNotes(t *testing.T) {
	long := strings.Repeat("a", maxProfileNotesLen+50)
	// Multibyte runes: truncation must count runes, not bytes.
	multibyte := strings.Repeat("é", maxProfileNotesLen+1)

	tests := []struct {
		name string
		in   *string
		want *string
	}{
		{"nil keeps existing", nil, nil},
		{"empty clears", strPtr(""), strPtr("")},
		{"whitespace-only clears", strPtr("  \n\t "), strPtr("")},
		{"trims surrounding whitespace", strPtr("  - likes food\n"), strPtr("- likes food")},
		{"under cap unchanged", strPtr("- vegetarian"), strPtr("- vegetarian")},
		{"over cap truncated", strPtr(long), strPtr(long[:maxProfileNotesLen])},
		{"multibyte truncated at rune boundary", strPtr(multibyte), strPtr(strings.Repeat("é", maxProfileNotesLen))},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := normalizeNotes(tt.in)
			if (got == nil) != (tt.want == nil) {
				t.Fatalf("normalizeNotes() = %v, want %v", got, tt.want)
			}
			if got != nil && *got != *tt.want {
				t.Fatalf("normalizeNotes() = %q (len %d), want %q (len %d)", *got, len(*got), *tt.want, len(*tt.want))
			}
		})
	}
}
