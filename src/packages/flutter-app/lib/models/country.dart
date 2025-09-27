import 'package:json_annotation/json_annotation.dart';
import 'season.dart';

part 'country.g.dart';

@JsonSerializable()
class Country {
  final String code;
  final String name;
  final String capital;
  final double latitude;
  final double longitude;
  
  @JsonKey(name: 'ideal_seasons')
  final List<Season> idealSeasons;
  
  @JsonKey(name: 'avoid_months')
  final List<int> avoidMonths;
  
  @JsonKey(name: 'min_stay_days')
  final int minStayDays;
  
  final String continent;
  final String currency;

  const Country({
    required this.code,
    required this.name,
    required this.capital,
    required this.latitude,
    required this.longitude,
    required this.idealSeasons,
    required this.avoidMonths,
    required this.minStayDays,
    required this.continent,
    required this.currency,
  });

  factory Country.fromJson(Map<String, dynamic> json) =>
      _$CountryFromJson(json);

  Map<String, dynamic> toJson() => _$CountryToJson(this);

  Country copyWith({
    String? code,
    String? name,
    String? capital,
    double? latitude,
    double? longitude,
    List<Season>? idealSeasons,
    List<int>? avoidMonths,
    int? minStayDays,
    String? continent,
    String? currency,
  }) {
    return Country(
      code: code ?? this.code,
      name: name ?? this.name,
      capital: capital ?? this.capital,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      idealSeasons: idealSeasons ?? this.idealSeasons,
      avoidMonths: avoidMonths ?? this.avoidMonths,
      minStayDays: minStayDays ?? this.minStayDays,
      continent: continent ?? this.continent,
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() {
    return 'Country(code: $code, name: $name, capital: $capital, continent: $continent, minStayDays: $minStayDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country &&
        other.code == code &&
        other.name == name &&
        other.capital == capital &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.idealSeasons == idealSeasons &&
        other.avoidMonths == avoidMonths &&
        other.minStayDays == minStayDays &&
        other.continent == continent &&
        other.currency == currency;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        name.hashCode ^
        capital.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        idealSeasons.hashCode ^
        avoidMonths.hashCode ^
        minStayDays.hashCode ^
        continent.hashCode ^
        currency.hashCode;
  }
}
