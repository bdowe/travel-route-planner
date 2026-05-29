# Plan: Activities & Dining

> **HOW.** Mirrors Phases 1–3 patterns; deliberately small.

## Technical Approach
Extend `itinerary_items` with a nullable `category` column, plumb it through
sqlc → `persistTrip` → `ItineraryItemResponse` → Flutter model. Agent's
`create_itinerary` tool gets an optional per-location `category` enum and a base
prompt that biases toward a mix of attractions + dining (the existing
`personalizedSystemPrompt` still appends preferences on top).

## Go API Changes
- **Migration `migrations/00006_itinerary_categories.sql`:**
  `ALTER TABLE itinerary_items ADD COLUMN category text;` — nullable; allowed
  set enforced in Go (not DB).
- `make api-sqlc` regenerates `store.ItineraryItem.Category *string` and
  `store.CreateItineraryItemParams.Category *string`.
- **`plan_handler.go`:**
  - In `createTool` schema, add `category` (type string, `enum: ["attraction","restaurant"]`).
  - Update `basePrompt` with one sentence biasing toward a mix of attractions
    and dining, instructing the model to tag each location.
- **`trip_handler.go`:**
  - `persistTrip`: read `loc["category"]` as `string`, lowercase/trim, accept
    only `attraction`/`restaurant` (else nil), pass into `CreateItineraryItemParams`.
  - `ItineraryItemResponse` gains `Category *string` (`json:"category,omitempty"`).
  - `toTripResponse` maps `it.Category` through.

## Flutter Changes
- **`models/itinerary_item.dart`:** add `final String? category;`
  (`@JsonKey(name: 'category')`); `make flutter-build-models`.
- **`screens/trip_detail_screen.dart`:**
  - Add a small filter chip row above the items (All / Attractions / Restaurants).
    Store the selected filter in `_TripDetailScreenState`.
  - Replace the item `leading: CircleAvatar(...)` with a switch on `item.category`:
    `restaurant` → `Icons.restaurant`, `attraction` → `Icons.attractions`, null →
    the existing numbered avatar.
  - When the filter is non-All, `where` the items by category before iterating.

## Contract Parity
| JSON key | Go (`ItineraryItemResponse`) | Dart (`ItineraryItem`) | Nullable |
|---|---|---|---|
| `category` | `*string` | `String?` | yes |

## Reuse / grounding
- **`personalizedSystemPrompt`** (Phase 2) keeps doing the personalization;
  this phase only changes the *base* prompt and the tool schema.
- **`persistTrip`** location-map iteration is the natural seam — same pattern
  used for `place_id`/`address`.
- **`MapGoogleTypeToCategory`** (`places_service.go`) is a reference if the
  agent ever needs to fall back to type-inference, but the agent supplies the
  category directly here.

## Verification
1. `make api-sqlc`, `api-fmt`/`api-vet`; migration applies on boot.
2. Extend `TestPersistTripAutoSave` (in-session throwaway): a 3-item payload
   mixing `category: "attraction"`, `category: "restaurant"`, and unset →
   stored Categories round-trip as `*string` matching expectations (nil for unset).
3. curl (Postgres + API): psql-seed items with categories; `GET /trips/{id}` items
   carry `category` and omit it when null. (LLM tool-call path not testable here.)
4. `make flutter-build-models`, `flutter analyze` (0 errors), `flutter build web`;
   trip detail shows the right icon per category and the filter chips narrow the list.
