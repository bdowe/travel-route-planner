// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Country _$CountryFromJson(Map<String, dynamic> json) => Country(
      code: json['code'] as String,
      name: json['name'] as String,
      capital: json['capital'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      idealSeasons: (json['ideal_seasons'] as List<dynamic>)
          .map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
      avoidMonths: (json['avoid_months'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      minStayDays: (json['min_stay_days'] as num).toInt(),
      continent: json['continent'] as String,
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$CountryToJson(Country instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'capital': instance.capital,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'ideal_seasons': instance.idealSeasons,
      'avoid_months': instance.avoidMonths,
      'min_stay_days': instance.minStayDays,
      'continent': instance.continent,
      'currency': instance.currency,
    };
