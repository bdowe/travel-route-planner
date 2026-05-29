import 'package:json_annotation/json_annotation.dart';

part 'itinerary_item.g.dart';

@JsonSerializable()
class ItineraryItem {
  final String id;
  final int position;
  final String name;
  @JsonKey(name: 'place_id')
  final String? placeId;
  final String? address;
  final double latitude;
  final double longitude;
  final String? category;

  const ItineraryItem({
    required this.id,
    required this.position,
    required this.name,
    this.placeId,
    this.address,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) =>
      _$ItineraryItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItineraryItemToJson(this);
}
