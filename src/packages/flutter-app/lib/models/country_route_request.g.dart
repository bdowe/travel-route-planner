// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_route_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountryRouteRequest _$CountryRouteRequestFromJson(Map<String, dynamic> json) =>
    CountryRouteRequest(
      countries: (json['countries'] as List<dynamic>)
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList(),
      startCountry: json['start_country'] as String?,
      tripStartDate: json['trip_start_date'] as String?,
      tripDurationDays: (json['trip_duration_days'] as num?)?.toInt(),
      optimizeFor: json['optimize_for'] as String,
      returnToStart: json['return_to_start'] as bool,
    );

Map<String, dynamic> _$CountryRouteRequestToJson(
  CountryRouteRequest instance,
) => <String, dynamic>{
  'countries': instance.countries,
  'start_country': instance.startCountry,
  'trip_start_date': instance.tripStartDate,
  'trip_duration_days': instance.tripDurationDays,
  'optimize_for': instance.optimizeFor,
  'return_to_start': instance.returnToStart,
};
