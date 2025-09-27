import 'package:json_annotation/json_annotation.dart';
import 'operating_hours.dart';

part 'location.g.dart';

@JsonSerializable()
class Location {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? category;
  
  @JsonKey(name: 'visit_duration_minutes')
  final int? visitDurationMinutes;
  
  final OperatingHours? hours;

  const Location({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.category,
    this.visitDurationMinutes,
    this.hours,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  Location copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? category,
    int? visitDurationMinutes,
    OperatingHours? hours,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      category: category ?? this.category,
      visitDurationMinutes: visitDurationMinutes ?? this.visitDurationMinutes,
      hours: hours ?? this.hours,
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, name: $name, latitude: $latitude, longitude: $longitude, address: $address, category: $category, visitDurationMinutes: $visitDurationMinutes, hours: $hours)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        other.category == category &&
        other.visitDurationMinutes == visitDurationMinutes &&
        other.hours == hours;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        address.hashCode ^
        category.hashCode ^
        visitDurationMinutes.hashCode ^
        hours.hashCode;
  }
}
