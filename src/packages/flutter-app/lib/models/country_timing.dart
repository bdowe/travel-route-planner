import 'package:json_annotation/json_annotation.dart';
import 'country.dart';

part 'country_timing.g.dart';

@JsonSerializable()
class CountryTiming {
  final Country country;
  
  @JsonKey(name: 'arrival_date')
  final String arrivalDate;
  
  @JsonKey(name: 'departure_date')
  final String departureDate;
  
  @JsonKey(name: 'stay_days')
  final int stayDays;
  
  @JsonKey(name: 'travel_days_from_previous')
  final int travelDaysFromPrevious;
  
  @JsonKey(name: 'seasonal_score')
  final double seasonalScore;

  const CountryTiming({
    required this.country,
    required this.arrivalDate,
    required this.departureDate,
    required this.stayDays,
    required this.travelDaysFromPrevious,
    required this.seasonalScore,
  });

  factory CountryTiming.fromJson(Map<String, dynamic> json) =>
      _$CountryTimingFromJson(json);

  Map<String, dynamic> toJson() => _$CountryTimingToJson(this);

  @override
  String toString() {
    return 'CountryTiming(country: ${country.name}, arrivalDate: $arrivalDate, departureDate: $departureDate, stayDays: $stayDays, seasonalScore: $seasonalScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryTiming &&
        other.country == country &&
        other.arrivalDate == arrivalDate &&
        other.departureDate == departureDate &&
        other.stayDays == stayDays &&
        other.travelDaysFromPrevious == travelDaysFromPrevious &&
        other.seasonalScore == seasonalScore;
  }

  @override
  int get hashCode {
    return country.hashCode ^
        arrivalDate.hashCode ^
        departureDate.hashCode ^
        stayDays.hashCode ^
        travelDaysFromPrevious.hashCode ^
        seasonalScore.hashCode;
  }
}
