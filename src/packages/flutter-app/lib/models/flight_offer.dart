import 'package:json_annotation/json_annotation.dart';
import 'flight_leg.dart';

part 'flight_offer.g.dart';

@JsonSerializable(explicitToJson: true)
class FlightOffer {
  final String id;
  final double price;
  final String currency;
  final int stops;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(defaultValue: <String>[])
  final List<String> airlines;
  @JsonKey(name: 'airline_code')
  final String? airlineCode;
  @JsonKey(name: 'airline_logo_url')
  final String? airlineLogoUrl;
  @JsonKey(name: 'depart_time')
  final String departTime;
  @JsonKey(name: 'arrive_time')
  final String arriveTime;
  @JsonKey(defaultValue: <FlightLeg>[])
  final List<FlightLeg> segments;
  @JsonKey(name: 'booking_url')
  final String? bookingUrl;

  final double score;
  @JsonKey(name: 'price_score')
  final double priceScore;
  @JsonKey(name: 'duration_score')
  final double durationScore;
  @JsonKey(name: 'stops_score')
  final double stopsScore;

  const FlightOffer({
    required this.id,
    required this.price,
    required this.currency,
    required this.stops,
    required this.durationMinutes,
    required this.airlines,
    this.airlineCode,
    this.airlineLogoUrl,
    required this.departTime,
    required this.arriveTime,
    required this.segments,
    this.bookingUrl,
    this.score = 0,
    this.priceScore = 0,
    this.durationScore = 0,
    this.stopsScore = 0,
  });

  /// "5h 30m" style duration label.
  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String get stopsLabel => switch (stops) {
        0 => 'Nonstop',
        1 => '1 stop',
        _ => '$stops stops',
      };

  /// Departure clock time, e.g. "10:50". Empty if unparseable.
  String get departClock => _clock(departTime);

  /// Arrival clock time, e.g. "00:47". Empty if unparseable.
  String get arriveClock => _clock(arriveTime);

  /// How many calendar days after departure the flight arrives (0 = same day,
  /// 1 = next day) — for the "+1" overnight indicator.
  int get arrivalDayOffset {
    final d = DateTime.tryParse(departTime);
    final a = DateTime.tryParse(arriveTime);
    if (d == null || a == null) return 0;
    return DateTime(a.year, a.month, a.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
  }

  static String _clock(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  factory FlightOffer.fromJson(Map<String, dynamic> json) =>
      _$FlightOfferFromJson(json);
  Map<String, dynamic> toJson() => _$FlightOfferToJson(this);
}
