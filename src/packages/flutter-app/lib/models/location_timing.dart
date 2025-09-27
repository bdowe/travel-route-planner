import 'package:json_annotation/json_annotation.dart';
import 'location.dart';

part 'location_timing.g.dart';

@JsonSerializable()
class LocationTiming {
  final Location location;
  
  @JsonKey(name: 'arrival_time')
  final String arrivalTime;
  
  @JsonKey(name: 'departure_time')
  final String departureTime;
  
  @JsonKey(name: 'visit_duration_minutes')
  final int visitDurationMin;
  
  @JsonKey(name: 'travel_from_previous_minutes')
  final int travelFromPreviousMin;

  const LocationTiming({
    required this.location,
    required this.arrivalTime,
    required this.departureTime,
    required this.visitDurationMin,
    required this.travelFromPreviousMin,
  });

  factory LocationTiming.fromJson(Map<String, dynamic> json) =>
      _$LocationTimingFromJson(json);

  Map<String, dynamic> toJson() => _$LocationTimingToJson(this);

  @override
  String toString() {
    return 'LocationTiming(location: ${location.name}, arrivalTime: $arrivalTime, departureTime: $departureTime, visitDurationMin: $visitDurationMin, travelFromPreviousMin: $travelFromPreviousMin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationTiming &&
        other.location == location &&
        other.arrivalTime == arrivalTime &&
        other.departureTime == departureTime &&
        other.visitDurationMin == visitDurationMin &&
        other.travelFromPreviousMin == travelFromPreviousMin;
  }

  @override
  int get hashCode {
    return location.hashCode ^
        arrivalTime.hashCode ^
        departureTime.hashCode ^
        visitDurationMin.hashCode ^
        travelFromPreviousMin.hashCode;
  }
}
