import 'package:json_annotation/json_annotation.dart';
import 'location.dart';

part 'route_request.g.dart';

@JsonSerializable()
class RouteRequest {
  final List<Location> locations;
  
  @JsonKey(name: 'start_index')
  final int? startIndex;
  
  @JsonKey(name: 'return_to_start')
  final bool returnToStart;
  
  @JsonKey(name: 'start_time')
  final String? startTime;
  
  @JsonKey(name: 'start_date')
  final String? startDate;

  const RouteRequest({
    required this.locations,
    this.startIndex,
    required this.returnToStart,
    this.startTime,
    this.startDate,
  });

  factory RouteRequest.fromJson(Map<String, dynamic> json) =>
      _$RouteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RouteRequestToJson(this);

  RouteRequest copyWith({
    List<Location>? locations,
    int? startIndex,
    bool? returnToStart,
    String? startTime,
    String? startDate,
  }) {
    return RouteRequest(
      locations: locations ?? this.locations,
      startIndex: startIndex ?? this.startIndex,
      returnToStart: returnToStart ?? this.returnToStart,
      startTime: startTime ?? this.startTime,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  String toString() {
    return 'RouteRequest(locations: ${locations.length} locations, startIndex: $startIndex, returnToStart: $returnToStart, startTime: $startTime, startDate: $startDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteRequest &&
        other.locations == locations &&
        other.startIndex == startIndex &&
        other.returnToStart == returnToStart &&
        other.startTime == startTime &&
        other.startDate == startDate;
  }

  @override
  int get hashCode {
    return locations.hashCode ^
        startIndex.hashCode ^
        returnToStart.hashCode ^
        startTime.hashCode ^
        startDate.hashCode;
  }
}
