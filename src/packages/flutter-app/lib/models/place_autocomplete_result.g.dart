// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_autocomplete_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceAutocompleteResult _$PlaceAutocompleteResultFromJson(
        Map<String, dynamic> json) =>
    PlaceAutocompleteResult(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      types: (json['types'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$PlaceAutocompleteResultToJson(
        PlaceAutocompleteResult instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'description': instance.description,
      'types': instance.types,
    };
