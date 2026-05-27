// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_route_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountryRouteResponse _$CountryRouteResponseFromJson(
        Map<String, dynamic> json) =>
    CountryRouteResponse(
      optimizedRoute: (json['optimized_route'] as List<dynamic>)
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList(),
      countryTimings: (json['country_timings'] as List<dynamic>)
          .map((e) => CountryTiming.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      totalTripDays: (json['total_trip_days'] as num).toInt(),
      totalTravelDays: (json['total_travel_days'] as num).toInt(),
      totalStayDays: (json['total_stay_days'] as num).toInt(),
      seasonalScore: (json['seasonal_score'] as num).toDouble(),
      distanceScore: (json['distance_score'] as num).toDouble(),
      overallScore: (json['overall_score'] as num).toDouble(),
      algorithm: json['algorithm_used'] as String,
      optimizationFocus: json['optimization_focus'] as String,
      countryCount: (json['country_count'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$CountryRouteResponseToJson(
        CountryRouteResponse instance) =>
    <String, dynamic>{
      'optimized_route': instance.optimizedRoute,
      'country_timings': instance.countryTimings,
      'total_distance_km': instance.totalDistanceKm,
      'total_trip_days': instance.totalTripDays,
      'total_travel_days': instance.totalTravelDays,
      'total_stay_days': instance.totalStayDays,
      'seasonal_score': instance.seasonalScore,
      'distance_score': instance.distanceScore,
      'overall_score': instance.overallScore,
      'algorithm_used': instance.algorithm,
      'optimization_focus': instance.optimizationFocus,
      'country_count': instance.countryCount,
      'status': instance.status,
    };
