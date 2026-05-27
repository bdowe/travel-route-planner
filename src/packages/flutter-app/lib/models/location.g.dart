// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      id: json['id'] as String,
      name: json['name'] as String,
      placeId: json['place_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      category: json['category'] as String?,
      visitDurationMinutes: (json['visit_duration_minutes'] as num?)?.toInt(),
      hours: json['hours'] == null
          ? null
          : OperatingHours.fromJson(json['hours'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'place_id': instance.placeId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'category': instance.category,
      'visit_duration_minutes': instance.visitDurationMinutes,
      'hours': instance.hours,
    };
