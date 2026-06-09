# Plan: Flights & Transport

> **HOW.** Mirrors the Phase-3 accommodation pattern line-for-line.

## Technical Approach

A provider-agnostic transport layer: `TransportProvider` interface with Google
Flights, Kayak (flight), and Rome2Rio (ground) `SearchURL` builders (deep-link
handoff today; a listing-returning provider can be added behind the same
interface later). A unified `trip_segments` table (many per trip, tagged by
`mode`) with add/list/delete behind `authMiddleware` + trip ownership; the
trip-detail response gains a `segments` array. A light agent `suggest_transport`
tool surfaces the same links.

## Go API Changes
- **Migration `migrations/00007_trip_segments.sql`:** `trip_segments` (id, `trip_id` FK
  CASCADE, `mode` NOT NULL, origin/destination/provider/url/price_note/notes,
  depart_date/arrive_date, timestamps + `set_updated_at` trigger, index on trip_id).
- **`query/segments.sql`:** `CreateSegment`, `ListSegmentsByTrip` (`ORDER BY
  depart_date ASC NULLS LAST, created_at ASC`), `DeleteSegment` (`WHERE id=$1 AND
  trip_id=$2`). `make api-sqlc`.
- **`transport_service.go`:** `TransportQuery`, `TransportProvider` interface,
  `googleFlightsProvider`/`kayakProvider`/`rome2rioProvider` `SearchURL`,
  `transportLinks(q)` helper filtered by mode.
- **`segment_handler.go`:** `transportLinksHandler` (parse query, 400 if missing),
  `addSegmentHandler` (verify trip ownership, validate mode, parse dates,
  `CreateSegment`), `deleteSegmentHandler` (404 if 0 rows). Reuse `ownedTrip`
  from `accommodation_handler.go`, `writeJSON`/`writeJSONError`, `parseDateParam`/`dateToPtr`.
- **`trip_handler.go`:** extend `TripResponse` with `Segments []SegmentResponse`;
  load via `ListSegmentsByTrip` in `getTripHandler`; pass through `toTripResponse`.
- **`plan_handler.go`:** `suggest_transport` tool (always available) → emits
  provider links via a custom `transport` SSE event.
- **`main.go`:** register `GET /transport-links` (open), `POST /trips/{id}/segments`
  + `DELETE /trips/{id}/segments/{segmentId}` (authed); startup logs.

## Flutter Changes
- `models/trip_segment.dart` (+ `.g.dart`); add `segments` to `models/trip.dart`.
- `services/transport_api_service.dart`: `transportLinks`, `addSegment`, `deleteSegment` (bearer from `ApiClient`).
- `providers/transport_provider.dart`: `transportApiServiceProvider`.
- `screens/trip_detail_screen.dart`: a **Travel** section — list segments with
  mode-aware leading icons (`flight`, `train`, `directions_bus`, `directions_car`,
  `directions_boat`, `route`); **Find flights** / **Find ground transport** dialogs
  (origin text input; destination/dates prefilled) → fetch links → `url_launcher`;
  **Add a segment** form (mode, origin, destination, dates, optional notes).

## Contract Parity
| JSON key | Go (`SegmentResponse`) | Dart (`TripSegment`) | Nullable |
|---|---|---|---|
| `id` | `string` | `String` | no |
| `mode` | `string` | `String` | no |
| `origin` | `*string` | `String?` | yes |
| `destination` | `*string` | `String?` | yes |
| `depart_date` | `*string` (YYYY-MM-DD) | `String?` | yes |
| `arrive_date` | `*string` (YYYY-MM-DD) | `String?` | yes |
| `provider` | `*string` | `String?` | yes |
| `url` | `*string` | `String?` | yes |
| `price_note` | `*string` | `String?` | yes |
| `notes` | `*string` | `String?` | yes |

## Verification
1. `make api-sqlc`, `api-fmt`/`api-vet`; migration applies.
2. `go test` for `SearchURL` (host/path, encoded origin/destination, dates,
   return only when present, mode filtering).
3. curl: `/transport-links` valid URLs per mode; add → appears in `GET /trips/{id}`;
   delete; other-user → 404; unauth → 401.
4. `flutter analyze` clean; `flutter build web` succeeds; Travel section
   find/add/delete works.
