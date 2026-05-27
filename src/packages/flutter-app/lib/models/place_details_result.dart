import 'package:json_annotation/json_annotation.dart';

part 'place_details_result.g.dart';

@JsonSerializable()
class PlaceDetailsResult {
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
  
  @JsonKey(name: 'opening_hours')
  final GoogleOpeningHours? openingHours;
  
  final String? website;
  
  @JsonKey(name: 'formatted_phone_number')
  final String? phoneNumber;

  const PlaceDetailsResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.rating,
    this.priceLevel,
    this.openingHours,
    this.website,
    this.phoneNumber,
  });

  factory PlaceDetailsResult.fromJson(Map<String, dynamic> json) =>
      _$PlaceDetailsResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceDetailsResultToJson(this);

  @override
  String toString() {
    return 'PlaceDetailsResult(placeId: $placeId, name: $name, address: $address, latitude: $latitude, longitude: $longitude, types: $types, rating: $rating, priceLevel: $priceLevel, openingHours: $openingHours, website: $website, phoneNumber: $phoneNumber)';
  }
}

@JsonSerializable()
class GoogleOpeningHours {
  @JsonKey(name: 'open_now')
  final bool openNow;
  
  @JsonKey(name: 'weekday_text')
  final List<String> weekdayText;

  const GoogleOpeningHours({
    required this.openNow,
    required this.weekdayText,
  });

  factory GoogleOpeningHours.fromJson(Map<String, dynamic> json) =>
      _$GoogleOpeningHoursFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleOpeningHoursToJson(this);

  @override
  String toString() {
    return 'GoogleOpeningHours(openNow: $openNow, weekdayText: $weekdayText)';
  }
}
