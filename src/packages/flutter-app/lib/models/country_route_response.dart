import 'package:json_annotation/json_annotation.dart';
import 'country.dart';
import 'country_timing.dart';

part 'country_route_response.g.dart';

@JsonSerializable()
class CountryRouteResponse {
  @JsonKey(name: 'optimized_route')
  final List<Country> optimizedRoute;
  
  @JsonKey(name: 'country_timings')
  final List<CountryTiming> countryTimings;
  
  @JsonKey(name: 'total_distance_km')
  final double totalDistanceKm;
  
  @JsonKey(name: 'total_trip_days')
  final int totalTripDays;
  
  @JsonKey(name: 'total_travel_days')
  final int totalTravelDays;
  
  @JsonKey(name: 'total_stay_days')
  final int totalStayDays;
  
  @JsonKey(name: 'seasonal_score')
  final double seasonalScore;
  
  @JsonKey(name: 'distance_score')
  final double distanceScore;
  
  @JsonKey(name: 'overall_score')
  final double overallScore;
  
  @JsonKey(name: 'algorithm_used')
  final String algorithm;
  
  @JsonKey(name: 'optimization_focus')
  final String optimizationFocus;
  
  @JsonKey(name: 'country_count')
  final int countryCount;
  
  final String status;

  const CountryRouteResponse({
    required this.optimizedRoute,
    required this.countryTimings,
    required this.totalDistanceKm,
    required this.totalTripDays,
    required this.totalTravelDays,
    required this.totalStayDays,
    required this.seasonalScore,
    required this.distanceScore,
    required this.overallScore,
    required this.algorithm,
    required this.optimizationFocus,
    required this.countryCount,
    required this.status,
  });

  factory CountryRouteResponse.fromJson(Map<String, dynamic> json) =>
      _$CountryRouteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CountryRouteResponseToJson(this);

  // Helper methods for formatting
  String get totalDistanceFormatted => '${totalDistanceKm.toStringAsFixed(0)} km';
  
  String get seasonalScoreFormatted => '${seasonalScore.toStringAsFixed(1)}/10';
  String get distanceScoreFormatted => '${distanceScore.toStringAsFixed(1)}/10';
  String get overallScoreFormatted => '${overallScore.toStringAsFixed(1)}/10';
  
  String get tripDurationFormatted {
    if (totalTripDays == 1) return '1 day';
    return '$totalTripDays days';
  }
  
  String get travelDurationFormatted {
    if (totalTravelDays == 1) return '1 day';
    return '$totalTravelDays days';
  }
  
  String get stayDurationFormatted {
    if (totalStayDays == 1) return '1 day';
    return '$totalStayDays days';
  }

  @override
  String toString() {
    return 'CountryRouteResponse(optimizedRoute: ${optimizedRoute.length} countries, totalDistanceKm: $totalDistanceKm, optimizationFocus: $optimizationFocus, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryRouteResponse &&
        other.optimizedRoute == optimizedRoute &&
        other.countryTimings == countryTimings &&
        other.totalDistanceKm == totalDistanceKm &&
        other.totalTripDays == totalTripDays &&
        other.totalTravelDays == totalTravelDays &&
        other.totalStayDays == totalStayDays &&
        other.seasonalScore == seasonalScore &&
        other.distanceScore == distanceScore &&
        other.overallScore == overallScore &&
        other.algorithm == algorithm &&
        other.optimizationFocus == optimizationFocus &&
        other.countryCount == countryCount &&
        other.status == status;
  }

  @override
  int get hashCode {
    return optimizedRoute.hashCode ^
        countryTimings.hashCode ^
        totalDistanceKm.hashCode ^
        totalTripDays.hashCode ^
        totalTravelDays.hashCode ^
        totalStayDays.hashCode ^
        seasonalScore.hashCode ^
        distanceScore.hashCode ^
        overallScore.hashCode ^
        algorithm.hashCode ^
        optimizationFocus.hashCode ^
        countryCount.hashCode ^
        status.hashCode;
  }
}
