// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_timing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountryTiming _$CountryTimingFromJson(Map<String, dynamic> json) =>
    CountryTiming(
      country: Country.fromJson(json['country'] as Map<String, dynamic>),
      arrivalDate: json['arrival_date'] as String,
      departureDate: json['departure_date'] as String,
      stayDays: (json['stay_days'] as num).toInt(),
      travelDaysFromPrevious:
          (json['travel_days_from_previous'] as num).toInt(),
      seasonalScore: (json['seasonal_score'] as num).toDouble(),
    );

Map<String, dynamic> _$CountryTimingToJson(CountryTiming instance) =>
    <String, dynamic>{
      'country': instance.country,
      'arrival_date': instance.arrivalDate,
      'departure_date': instance.departureDate,
      'stay_days': instance.stayDays,
      'travel_days_from_previous': instance.travelDaysFromPrevious,
      'seasonal_score': instance.seasonalScore,
    };
