import 'package:json_annotation/json_annotation.dart';
import 'location.dart';

part 'location_timing.g.dart';

@JsonSerializable()
class LocationTiming {
  final Location location;
  
  @JsonKey(name: 'arrival_time', defaultValue: '')
  final String arrivalTime;

  @JsonKey(name: 'departure_time', defaultValue: '')
  final String departureTime;

  @JsonKey(name: 'visit_duration_minutes')
  final int visitDurationMin;

  @JsonKey(name: 'travel_to_next_minutes', defaultValue: 0)
  final int travelToNextMin;

  const LocationTiming({
    required this.location,
    required this.arrivalTime,
    required this.departureTime,
    required this.visitDurationMin,
    required this.travelToNextMin,
  });

  factory LocationTiming.fromJson(Map<String, dynamic> json) =>
      _$LocationTimingFromJson(json);

  Map<String, dynamic> toJson() => _$LocationTimingToJson(this);

  @override
  String toString() {
    return 'LocationTiming(location: ${location.name}, arrivalTime: $arrivalTime, departureTime: $departureTime, visitDurationMin: $visitDurationMin, travelToNextMin: $travelToNextMin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationTiming &&
        other.location == location &&
        other.arrivalTime == arrivalTime &&
        other.departureTime == departureTime &&
        other.visitDurationMin == visitDurationMin &&
        other.travelToNextMin == travelToNextMin;
  }

  @override
  int get hashCode {
    return location.hashCode ^
        arrivalTime.hashCode ^
        departureTime.hashCode ^
        visitDurationMin.hashCode ^
        travelToNextMin.hashCode;
  }
}
