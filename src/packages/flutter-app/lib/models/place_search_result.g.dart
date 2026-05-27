// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceSearchResult _$PlaceSearchResultFromJson(Map<String, dynamic> json) =>
    PlaceSearchResult(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: json['formatted_address'] as String? ?? '',
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      types:
          (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: (json['price_level'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlaceSearchResultToJson(PlaceSearchResult instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'name': instance.name,
      'formatted_address': instance.address,
      'lat': instance.latitude,
      'lng': instance.longitude,
      'types': instance.types,
      'rating': instance.rating,
      'price_level': instance.priceLevel,
    };
