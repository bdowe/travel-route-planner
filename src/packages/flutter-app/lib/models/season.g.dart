// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Season _$SeasonFromJson(Map<String, dynamic> json) => Season(
  name: json['name'] as String,
  description: json['description'] as String,
  startMonth: (json['start_month'] as num).toInt(),
  endMonth: (json['end_month'] as num).toInt(),
  score: (json['score'] as num).toDouble(),
);

Map<String, dynamic> _$SeasonToJson(Season instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'start_month': instance.startMonth,
  'end_month': instance.endMonth,
  'score': instance.score,
};
