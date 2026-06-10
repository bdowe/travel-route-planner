import 'package:json_annotation/json_annotation.dart';

part 'flight_leg.g.dart';

@JsonSerializable()
class FlightLeg {
  final String from;
  final String to;
  final String carrier;
  @JsonKey(name: 'flight_number')
  final String flightNumber;
  @JsonKey(name: 'depart_time')
  final String departTime;
  @JsonKey(name: 'arrive_time')
  final String arriveTime;

  const FlightLeg({
    required this.from,
    required this.to,
    required this.carrier,
    required this.flightNumber,
    required this.departTime,
    required this.arriveTime,
  });

  factory FlightLeg.fromJson(Map<String, dynamic> json) =>
      _$FlightLegFromJson(json);
  Map<String, dynamic> toJson() => _$FlightLegToJson(this);
}
