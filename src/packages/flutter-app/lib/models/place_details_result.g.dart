// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_details_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceDetailsResult _$PlaceDetailsResultFromJson(Map<String, dynamic> json) =>
    PlaceDetailsResult(
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
      openingHours: json['opening_hours'] == null
          ? null
          : GoogleOpeningHours.fromJson(
              json['opening_hours'] as Map<String, dynamic>),
      website: json['website'] as String?,
      phoneNumber: json['formatted_phone_number'] as String?,
    );

Map<String, dynamic> _$PlaceDetailsResultToJson(PlaceDetailsResult instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'name': instance.name,
      'formatted_address': instance.address,
      'lat': instance.latitude,
      'lng': instance.longitude,
      'types': instance.types,
      'rating': instance.rating,
      'price_level': instance.priceLevel,
      'opening_hours': instance.openingHours,
      'website': instance.website,
      'formatted_phone_number': instance.phoneNumber,
    };

GoogleOpeningHours _$GoogleOpeningHoursFromJson(Map<String, dynamic> json) =>
    GoogleOpeningHours(
      openNow: json['open_now'] as bool,
      weekdayText: (json['weekday_text'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$GoogleOpeningHoursToJson(GoogleOpeningHours instance) =>
    <String, dynamic>{
      'open_now': instance.openNow,
      'weekday_text': instance.weekdayText,
    };
