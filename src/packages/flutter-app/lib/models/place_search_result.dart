import 'package:json_annotation/json_annotation.dart';

part 'place_search_result.g.dart';

@JsonSerializable()
class PlaceSearchResult {
  @JsonKey(name: 'place_id')
  final String placeId;

  final String name;

  @JsonKey(name: 'formatted_address', defaultValue: '')
  final String address;

  @JsonKey(name: 'lat')
  final double latitude;

  @JsonKey(name: 'lng')
  final double longitude;

  @JsonKey(defaultValue: <String>[])
  final List<String> types;
  final double? rating;
  
  @JsonKey(name: 'price_level')
  final int? priceLevel;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.rating,
    this.priceLevel,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) =>
      _$PlaceSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceSearchResultToJson(this);

  @override
  String toString() {
    return 'PlaceSearchResult(placeId: $placeId, name: $name, address: $address, latitude: $latitude, longitude: $longitude, types: $types, rating: $rating, priceLevel: $priceLevel)';
  }
}
