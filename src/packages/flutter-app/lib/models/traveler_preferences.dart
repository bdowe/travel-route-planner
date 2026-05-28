import 'package:json_annotation/json_annotation.dart';

part 'traveler_preferences.g.dart';

@JsonSerializable()
class TravelerPreferences {
  final String? budget;
  final String? pace;
  final List<String> interests;

  const TravelerPreferences({this.budget, this.pace, this.interests = const []});

  factory TravelerPreferences.fromJson(Map<String, dynamic> json) =>
      _$TravelerPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$TravelerPreferencesToJson(this);
}
