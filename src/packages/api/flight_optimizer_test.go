package main

import "testing"

// leg is a tiny helper to build a single-segment offer with a given schedule.
func offer(id string, price float64, from, to, dep, arr string, dur, stops int) FlightOffer {
	return FlightOffer{
		ID:          id,
		Price:       price,
		Currency:    "USD",
		Stops:       stops,
		DurationMin: dur,
		DepartTime:  dep,
		ArriveTime:  arr,
		Segments:    []FlightLeg{{From: from, To: to, DepartTime: dep, ArriveTime: arr}},
	}
}

// Mirrors the real EWR->PAR Duffel response: four offers sharing one cheap
// nonstop schedule (resold under different carriers), plus two distinct ones.
func TestRankFlightOffersDedupesSharedSchedule(t *testing.T) {
	in := []FlightOffer{
		offer("iberia", 226.81, "EWR", "BVA", "2026-07-15T10:50:00", "2026-07-16T01:09:00", 499, 0),
		offer("ba", 234.23, "EWR", "BVA", "2026-07-15T10:50:00", "2026-07-16T01:09:00", 499, 0),
		offer("aa", 239.74, "EWR", "BVA", "2026-07-15T10:50:00", "2026-07-16T01:09:00", 499, 0),
		offer("duffel", 241.21, "EWR", "BVA", "2026-07-15T10:50:00", "2026-07-16T01:09:00", 499, 0),
		offer("tap", 374.00, "EWR", "ORY", "2026-07-15T17:30:00", "2026-07-16T11:00:00", 690, 1),
		offer("frenchbee", 424.50, "EWR", "ORY", "2026-07-15T23:00:00", "2026-07-16T12:15:00", 435, 0),
	}

	got := RankFlightOffers(in, "balanced")

	if len(got) != 3 {
		t.Fatalf("expected 3 distinct schedules after dedup, got %d", len(got))
	}
	// The shared cheap schedule must be represented exactly once, by Iberia (cheapest).
	count := 0
	for _, o := range got {
		if o.Segments[0].To == "BVA" {
			count++
			if o.ID != "iberia" {
				t.Errorf("expected cheapest BVA offer (iberia) to survive, got %q at $%.2f", o.ID, o.Price)
			}
		}
	}
	if count != 1 {
		t.Errorf("expected the shared BVA schedule to appear once, got %d", count)
	}
}

// twoStop builds a 3-leg EWR->hub1->hub2->FCO itinerary with fixed endpoints,
// varying only the middle (hub1->hub2) leg's timing — mirroring the real Duffel
// case where the same route at the same price appears several times.
func twoStop(id string, price float64, hub1, hub2, midDep, midArr string) FlightOffer {
	return FlightOffer{
		ID: id, Price: price, Currency: "USD", Stops: 2, DurationMin: 1145,
		DepartTime: "2026-07-15T23:10:00", ArriveTime: "2026-07-16T00:15:00",
		Segments: []FlightLeg{
			{From: "EWR", To: hub1, DepartTime: "2026-07-15T23:10:00", ArriveTime: "2026-07-16T10:55:00"},
			{From: hub1, To: hub2, DepartTime: midDep, ArriveTime: midArr},
			{From: hub2, To: "FCO", DepartTime: "2026-07-16T20:15:00", ArriveTime: "2026-07-16T00:15:00"},
		},
	}
}

func TestDedupCollapsesSameRouteDifferentLayoverTiming(t *testing.T) {
	// Same endpoints, same total times, same hubs (OPO, LIS), same price —
	// differ only in the OPO->LIS leg timing. These look identical on the card
	// and must collapse to one.
	in := []FlightOffer{
		twoStop("a", 390, "OPO", "LIS", "2026-07-16T12:35:00", "2026-07-16T13:25:00"),
		twoStop("b", 390, "OPO", "LIS", "2026-07-16T18:00:00", "2026-07-16T19:05:00"),
		twoStop("c", 390, "OPO", "LIS", "2026-07-16T16:00:00", "2026-07-16T17:00:00"),
	}
	got := dedupBySchedule(in)
	if len(got) != 1 {
		t.Fatalf("expected same-route/different-layover offers to collapse to 1, got %d", len(got))
	}
}

func TestDedupKeepsDifferentConnectingAirports(t *testing.T) {
	// Same endpoints and overall times but routed through different hubs — these
	// are genuinely different itineraries and must both survive.
	in := []FlightOffer{
		twoStop("via-opo", 390, "OPO", "LIS", "2026-07-16T12:35:00", "2026-07-16T13:25:00"),
		twoStop("via-mad", 390, "MAD", "LIS", "2026-07-16T12:35:00", "2026-07-16T13:25:00"),
	}
	got := dedupBySchedule(in)
	if len(got) != 2 {
		t.Fatalf("expected different-hub itineraries to stay separate, got %d", len(got))
	}
}

func TestDedupBySchedulePreservesOrderAndKeepsCheapest(t *testing.T) {
	in := []FlightOffer{
		offer("a-expensive", 500, "JFK", "CDG", "T1", "T2", 480, 0),
		offer("b-other", 300, "JFK", "ORY", "T3", "T4", 500, 1),
		offer("a-cheap", 250, "JFK", "CDG", "T1", "T2", 480, 0),
	}
	got := dedupBySchedule(in)
	if len(got) != 2 {
		t.Fatalf("expected 2 schedules, got %d", len(got))
	}
	if got[0].ID != "a-cheap" {
		t.Errorf("expected cheapest of shared schedule (a-cheap) in first slot, got %q", got[0].ID)
	}
	if got[0].Price != 250 {
		t.Errorf("expected price 250, got %v", got[0].Price)
	}
	if got[1].ID != "b-other" {
		t.Errorf("expected b-other preserved in second slot, got %q", got[1].ID)
	}
}
