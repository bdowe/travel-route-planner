import 'package:json_annotation/json_annotation.dart';
import 'country.dart';

part 'country_route_request.g.dart';

@JsonSerializable()
class CountryRouteRequest {
  final List<Country> countries;
  
  @JsonKey(name: 'start_country')
  final String? startCountry;
  
  @JsonKey(name: 'trip_start_date')
  final String? tripStartDate;
  
  @JsonKey(name: 'trip_duration_days')
  final int? tripDurationDays;
  
  @JsonKey(name: 'optimize_for')
  final String optimizeFor;
  
  @JsonKey(name: 'return_to_start')
  final bool returnToStart;

  const CountryRouteRequest({
    required this.countries,
    this.startCountry,
    this.tripStartDate,
    this.tripDurationDays,
    required this.optimizeFor,
    required this.returnToStart,
  });

  factory CountryRouteRequest.fromJson(Map<String, dynamic> json) =>
      _$CountryRouteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CountryRouteRequestToJson(this);

  CountryRouteRequest copyWith({
    List<Country>? countries,
    String? startCountry,
    String? tripStartDate,
    int? tripDurationDays,
    String? optimizeFor,
    bool? returnToStart,
  }) {
    return CountryRouteRequest(
      countries: countries ?? this.countries,
      startCountry: startCountry ?? this.startCountry,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripDurationDays: tripDurationDays ?? this.tripDurationDays,
      optimizeFor: optimizeFor ?? this.optimizeFor,
      returnToStart: returnToStart ?? this.returnToStart,
    );
  }

  @override
  String toString() {
    return 'CountryRouteRequest(countries: ${countries.length} countries, optimizeFor: $optimizeFor, returnToStart: $returnToStart)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryRouteRequest &&
        other.countries == countries &&
        other.startCountry == startCountry &&
        other.tripStartDate == tripStartDate &&
        other.tripDurationDays == tripDurationDays &&
        other.optimizeFor == optimizeFor &&
        other.returnToStart == returnToStart;
  }

  @override
  int get hashCode {
    return countries.hashCode ^
        startCountry.hashCode ^
        tripStartDate.hashCode ^
        tripDurationDays.hashCode ^
        optimizeFor.hashCode ^
        returnToStart.hashCode;
  }
}
