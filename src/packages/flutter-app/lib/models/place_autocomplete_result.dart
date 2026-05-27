import 'package:json_annotation/json_annotation.dart';

part 'place_autocomplete_result.g.dart';

@JsonSerializable()
class PlaceAutocompleteResult {
  @JsonKey(name: 'place_id')
  final String placeId;
  
  final String description;
  final List<String> types;

  const PlaceAutocompleteResult({
    required this.placeId,
    required this.description,
    required this.types,
  });

  factory PlaceAutocompleteResult.fromJson(Map<String, dynamic> json) =>
      _$PlaceAutocompleteResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceAutocompleteResultToJson(this);

  @override
  String toString() {
    return 'PlaceAutocompleteResult(placeId: $placeId, description: $description, types: $types)';
  }
}
