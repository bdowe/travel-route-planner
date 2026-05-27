// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteRequest _$RouteRequestFromJson(Map<String, dynamic> json) => RouteRequest(
      locations: (json['locations'] as List<dynamic>)
          .map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList(),
      startIndex: (json['start_index'] as num?)?.toInt(),
      returnToStart: json['return_to_start'] as bool,
      startTime: json['start_time'] as String?,
      startDate: json['start_date'] as String?,
    );

Map<String, dynamic> _$RouteRequestToJson(RouteRequest instance) =>
    <String, dynamic>{
      'locations': instance.locations,
      'start_index': instance.startIndex,
      'return_to_start': instance.returnToStart,
      'start_time': instance.startTime,
      'start_date': instance.startDate,
    };
