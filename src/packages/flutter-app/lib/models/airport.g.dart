// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airport.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Airport _$AirportFromJson(Map<String, dynamic> json) => Airport(
      iataCode: json['iata_code'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      subType: json['sub_type'] as String? ?? '',
    );

Map<String, dynamic> _$AirportToJson(Airport instance) => <String, dynamic>{
      'iata_code': instance.iataCode,
      'name': instance.name,
      'city': instance.city,
      'country': instance.country,
      'sub_type': instance.subType,
    };
