package main

import (
	"net/url"
	"strconv"
	"strings"
)

// TransportQuery describes a transport search between an origin and destination.
type TransportQuery struct {
	Mode        string // "flight" | "ground" | "" (any)
	Origin      string
	Destination string
	DepartDate  string // YYYY-MM-DD (optional)
	ReturnDate  string // YYYY-MM-DD (optional)
	Passengers  int    // optional
}

// TransportProvider is the source-agnostic shape for transport links. Today's
// implementations return a deep link; a future listing-returning provider
// (Duffel/Amadeus) can be added behind this same package without changing callers.
type TransportProvider interface {
	Name() string
	Mode() string // "flight" | "ground"
	SearchURL(q TransportQuery) string
}

type TransportLink struct {
	Provider string `json:"provider"`
	Mode     string `json:"mode"`
	URL      string `json:"url"`
}

// slugify normalizes a city/airport name for inclusion in URL path segments
// (Kayak/Rome2Rio use hyphenated forms).
func slugify(s string) string {
	return url.PathEscape(strings.ReplaceAll(strings.TrimSpace(s), " ", "-"))
}

type googleFlightsProvider struct{}

func (googleFlightsProvider) Name() string { return "google_flights" }
func (googleFlightsProvider) Mode() string { return "flight" }
func (googleFlightsProvider) SearchURL(q TransportQuery) string {
	parts := []string{"flights"}
	if q.Origin != "" {
		parts = append(parts, "from", q.Origin)
	}
	if q.Destination != "" {
		parts = append(parts, "to", q.Destination)
	}
	if q.DepartDate != "" {
		parts = append(parts, "on", q.DepartDate)
	}
	if q.ReturnDate != "" {
		parts = append(parts, "returning", q.ReturnDate)
	}
	query := strings.Join(parts, " ")
	return "https://www.google.com/travel/flights?" + url.Values{"q": {query}}.Encode()
}

type kayakProvider struct{}

func (kayakProvider) Name() string { return "kayak" }
func (kayakProvider) Mode() string { return "flight" }
func (kayakProvider) SearchURL(q TransportQuery) string {
	u := "https://www.kayak.com/flights/" + slugify(q.Origin) + "-" + slugify(q.Destination)
	if q.DepartDate != "" {
		u += "/" + q.DepartDate
	}
	if q.ReturnDate != "" {
		u += "/" + q.ReturnDate
	}
	if q.Passengers > 0 {
		u += "?adults=" + strconv.Itoa(q.Passengers)
	}
	return u
}

type rome2rioProvider struct{}

func (rome2rioProvider) Name() string { return "rome2rio" }
func (rome2rioProvider) Mode() string { return "ground" }
func (rome2rioProvider) SearchURL(q TransportQuery) string {
	return "https://www.rome2rio.com/map/" + slugify(q.Origin) + "/" + slugify(q.Destination)
}

func transportProviders() []TransportProvider {
	return []TransportProvider{googleFlightsProvider{}, kayakProvider{}, rome2rioProvider{}}
}

// transportLinks returns the matching browse links. If q.Mode is set ("flight"
// or "ground"), the result is filtered to providers serving that mode; an empty
// Mode returns every provider.
func transportLinks(q TransportQuery) []TransportLink {
	provs := transportProviders()
	out := make([]TransportLink, 0, len(provs))
	for _, p := range provs {
		if q.Mode != "" && p.Mode() != q.Mode {
			continue
		}
		out = append(out, TransportLink{Provider: p.Name(), Mode: p.Mode(), URL: p.SearchURL(q)})
	}
	return out
}
