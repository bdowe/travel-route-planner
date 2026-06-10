package main

import (
	"net/url"
	"strings"
)

// airlineSites maps an airline IATA code to its booking/home page. Best-effort
// for major carriers; offers from any other airline fall back to an
// airline-filtered Google Flights link (see flightBookingURL). Duffel does not
// expose a per-flight airline booking link, so these land on the carrier's own
// booking/search page rather than the exact itinerary.
var airlineSites = map[string]string{
	"AA": "https://www.aa.com",
	"DL": "https://www.delta.com",
	"UA": "https://www.united.com",
	"B6": "https://www.jetblue.com",
	"AS": "https://www.alaskaair.com",
	"WN": "https://www.southwest.com",
	"NK": "https://www.spirit.com",
	"F9": "https://www.flyfrontier.com",
	"HA": "https://www.hawaiianairlines.com",
	"AC": "https://www.aircanada.com",
	"WS": "https://www.westjet.com",
	"AM": "https://www.aeromexico.com",
	"AV": "https://www.avianca.com",
	"CM": "https://www.copaair.com",
	"LA": "https://www.latamairlines.com",
	"BA": "https://www.britishairways.com",
	"VS": "https://www.virginatlantic.com",
	"AF": "https://www.airfrance.com",
	"KL": "https://www.klm.com",
	"LH": "https://www.lufthansa.com",
	"LX": "https://www.swiss.com",
	"OS": "https://www.austrian.com",
	"IB": "https://www.iberia.com",
	"TP": "https://www.flytap.com",
	"EI": "https://www.aerlingus.com",
	"AY": "https://www.finnair.com",
	"SK": "https://www.flysas.com",
	"AZ": "https://www.ita-airways.com",
	"TK": "https://www.turkishairlines.com",
	"EK": "https://www.emirates.com",
	"QR": "https://www.qatarairways.com",
	"EY": "https://www.etihad.com",
	"SQ": "https://www.singaporeair.com",
	"CX": "https://www.cathaypacific.com",
	"QF": "https://www.qantas.com",
	"NH": "https://www.ana.co.jp",
	"JL": "https://www.jal.co.jp",
	"ET": "https://www.ethiopianairlines.com",
}

// flightBookingURL returns the airline's own booking site when the carrier is
// known, otherwise an airline-filtered Google Flights deep link for the route
// and dates (the airline name is added to the query so Google pre-filters to
// that carrier).
func flightBookingURL(airlineCode, airlineName, origin, destination, departDate, returnDate string) string {
	if site, ok := airlineSites[strings.ToUpper(strings.TrimSpace(airlineCode))]; ok {
		return site
	}

	parts := []string{"flights"}
	if origin != "" {
		parts = append(parts, "from", origin)
	}
	if destination != "" {
		parts = append(parts, "to", destination)
	}
	if departDate != "" {
		parts = append(parts, "on", departDate)
	}
	if returnDate != "" {
		parts = append(parts, "returning", returnDate)
	}
	if airlineName != "" {
		parts = append(parts, "on", airlineName)
	}
	query := strings.Join(parts, " ")
	return "https://www.google.com/travel/flights?" + url.Values{"q": {query}}.Encode()
}

// attachBookingURLs sets BookingURL on each offer from its airline plus the
// request's route and dates. Shared by the standalone /flights/search handler
// and the agent's search_flights tool so both surface a working link.
func attachBookingURLs(offers []FlightOffer, req FlightSearchRequest) {
	for i := range offers {
		name := ""
		if len(offers[i].Airlines) > 0 {
			name = offers[i].Airlines[0]
		}
		offers[i].BookingURL = flightBookingURL(
			offers[i].AirlineCode, name, req.Origin, req.Destination, req.DepartDate, req.ReturnDate)
	}
}
