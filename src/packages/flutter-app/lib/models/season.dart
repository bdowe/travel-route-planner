import 'package:json_annotation/json_annotation.dart';

part 'season.g.dart';

@JsonSerializable()
class Season {
  final String name;
  final String description;
  @JsonKey(name: 'start_month')
  final int startMonth;
  @JsonKey(name: 'end_month')
  final int endMonth;
  final double score;

  const Season({
    required this.name,
    required this.description,
    required this.startMonth,
    required this.endMonth,
    required this.score,
  });

  factory Season.fromJson(Map<String, dynamic> json) =>
      _$SeasonFromJson(json);

  Map<String, dynamic> toJson() => _$SeasonToJson(this);

  @override
  String toString() {
    return 'Season(name: $name, description: $description, startMonth: $startMonth, endMonth: $endMonth, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Season &&
        other.name == name &&
        other.description == description &&
        other.startMonth == startMonth &&
        other.endMonth == endMonth &&
        other.score == score;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        description.hashCode ^
        startMonth.hashCode ^
        endMonth.hashCode ^
        score.hashCode;
  }
}
