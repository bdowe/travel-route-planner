import 'package:json_annotation/json_annotation.dart';
import 'flight_offer.dart';

part 'flight_search_response.g.dart';

@JsonSerializable(explicitToJson: true)
class FlightSearchResponse {
  @JsonKey(defaultValue: <FlightOffer>[])
  final List<FlightOffer> offers;
  @JsonKey(name: 'best_offer_id')
  final String? bestOfferId;
  @JsonKey(name: 'optimize_for')
  final String optimizeFor;
  final int count;
  final String status;

  const FlightSearchResponse({
    required this.offers,
    this.bestOfferId,
    required this.optimizeFor,
    required this.count,
    required this.status,
  });

  factory FlightSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$FlightSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FlightSearchResponseToJson(this);
}
