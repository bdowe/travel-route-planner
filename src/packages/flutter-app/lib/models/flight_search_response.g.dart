// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlightSearchResponse _$FlightSearchResponseFromJson(
        Map<String, dynamic> json) =>
    FlightSearchResponse(
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => FlightOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bestOfferId: json['best_offer_id'] as String?,
      optimizeFor: json['optimize_for'] as String,
      count: (json['count'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$FlightSearchResponseToJson(
        FlightSearchResponse instance) =>
    <String, dynamic>{
      'offers': instance.offers.map((e) => e.toJson()).toList(),
      'best_offer_id': instance.bestOfferId,
      'optimize_for': instance.optimizeFor,
      'count': instance.count,
      'status': instance.status,
    };
