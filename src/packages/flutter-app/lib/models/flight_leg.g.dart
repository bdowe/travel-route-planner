// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_leg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlightLeg _$FlightLegFromJson(Map<String, dynamic> json) => FlightLeg(
      from: json['from'] as String,
      to: json['to'] as String,
      carrier: json['carrier'] as String,
      flightNumber: json['flight_number'] as String,
      departTime: json['depart_time'] as String,
      arriveTime: json['arrive_time'] as String,
    );

Map<String, dynamic> _$FlightLegToJson(FlightLeg instance) => <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'carrier': instance.carrier,
      'flight_number': instance.flightNumber,
      'depart_time': instance.departTime,
      'arrive_time': instance.arriveTime,
    };
