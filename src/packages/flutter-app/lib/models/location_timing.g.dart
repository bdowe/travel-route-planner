// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_timing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationTiming _$LocationTimingFromJson(Map<String, dynamic> json) =>
    LocationTiming(
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      arrivalTime: json['arrival_time'] as String,
      departureTime: json['departure_time'] as String,
      visitDurationMin: (json['visit_duration_minutes'] as num).toInt(),
      travelFromPreviousMin: (json['travel_from_previous_minutes'] as num)
          .toInt(),
    );

Map<String, dynamic> _$LocationTimingToJson(LocationTiming instance) =>
    <String, dynamic>{
      'location': instance.location,
      'arrival_time': instance.arrivalTime,
      'departure_time': instance.departureTime,
      'visit_duration_minutes': instance.visitDurationMin,
      'travel_from_previous_minutes': instance.travelFromPreviousMin,
    };
