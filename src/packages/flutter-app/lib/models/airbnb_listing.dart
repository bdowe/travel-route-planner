import 'package:json_annotation/json_annotation.dart';

part 'airbnb_listing.g.dart';

@JsonSerializable()
class AirbnbListingLocation {
  final String city;
  final String state;
  final String country;
  final double latitude;
  final double longitude;

  const AirbnbListingLocation({
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory AirbnbListingLocation.fromJson(Map<String, dynamic> json) =>
      _$AirbnbListingLocationFromJson(json);

  Map<String, dynamic> toJson() => _$AirbnbListingLocationToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirbnbListingLocation &&
        other.city == city &&
        other.state == state &&
        other.country == country &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode =>
      city.hashCode ^ state.hashCode ^ country.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}

@JsonSerializable()
class AirbnbHost {
  final String name;
  final String avatar;

  const AirbnbHost({required this.name, required this.avatar});

  factory AirbnbHost.fromJson(Map<String, dynamic> json) => _$AirbnbHostFromJson(json);

  Map<String, dynamic> toJson() => _$AirbnbHostToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirbnbHost && other.name == name && other.avatar == avatar;
  }

  @override
  int get hashCode => name.hashCode ^ avatar.hashCode;
}

@JsonSerializable()
class AirbnbPhoto {
  final String url;
  final String caption;

  const AirbnbPhoto({required this.url, required this.caption});

  factory AirbnbPhoto.fromJson(Map<String, dynamic> json) => _$AirbnbPhotoFromJson(json);

  Map<String, dynamic> toJson() => _$AirbnbPhotoToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirbnbPhoto && other.url == url && other.caption == caption;
  }

  @override
  int get hashCode => url.hashCode ^ caption.hashCode;
}

@JsonSerializable()
class AirbnbPricing {
  @JsonKey(name: 'nightly_rate')
  final double nightlyRate;
  final int nights;
  @JsonKey(name: 'cleaning_fee')
  final double cleaningFee;
  @JsonKey(name: 'service_fee')
  final double serviceFee;
  final double total;
  final String currency;

  const AirbnbPricing({
    required this.nightlyRate,
    required this.nights,
    required this.cleaningFee,
    required this.serviceFee,
    required this.total,
    required this.currency,
  });

  factory AirbnbPricing.fromJson(Map<String, dynamic> json) => _$AirbnbPricingFromJson(json);

  Map<String, dynamic> toJson() => _$AirbnbPricingToJson(this);

  bool get hasPricing => total > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirbnbPricing &&
        other.nightlyRate == nightlyRate &&
        other.nights == nights &&
        other.cleaningFee == cleaningFee &&
        other.serviceFee == serviceFee &&
        other.total == total &&
        other.currency == currency;
  }

  @override
  int get hashCode =>
      nightlyRate.hashCode ^
      nights.hashCode ^
      cleaningFee.hashCode ^
      serviceFee.hashCode ^
      total.hashCode ^
      currency.hashCode;
}

@JsonSerializable()
class AirbnbListing {
  @JsonKey(name: 'listing_id')
  final String listingId;
  final String url;
  final String title;
  final String description;
  @JsonKey(name: 'property_type')
  final String propertyType;
  @JsonKey(name: 'room_type')
  final String roomType;
  @JsonKey(name: 'max_guests')
  final int maxGuests;
  final int bedrooms;
  final double bathrooms;
  final int beds;
  final AirbnbListingLocation location;
  final AirbnbHost host;
  final double rating;
  @JsonKey(name: 'review_count')
  final int reviewCount;
  final List<AirbnbPhoto> photos;
  final List<String> amenities;
  @JsonKey(name: 'check_in')
  final String checkIn;
  @JsonKey(name: 'check_out')
  final String checkOut;
  final AirbnbPricing pricing;

  const AirbnbListing({
    required this.listingId,
    required this.url,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.roomType,
    required this.maxGuests,
    required this.bedrooms,
    required this.bathrooms,
    required this.beds,
    required this.location,
    required this.host,
    required this.rating,
    required this.reviewCount,
    required this.photos,
    required this.amenities,
    required this.checkIn,
    required this.checkOut,
    required this.pricing,
  });

  factory AirbnbListing.fromJson(Map<String, dynamic> json) => _$AirbnbListingFromJson(json);

  Map<String, dynamic> toJson() => _$AirbnbListingToJson(this);

  AirbnbListing copyWith({
    String? listingId,
    String? url,
    String? title,
    String? description,
    String? propertyType,
    String? roomType,
    int? maxGuests,
    int? bedrooms,
    double? bathrooms,
    int? beds,
    AirbnbListingLocation? location,
    AirbnbHost? host,
    double? rating,
    int? reviewCount,
    List<AirbnbPhoto>? photos,
    List<String>? amenities,
    String? checkIn,
    String? checkOut,
    AirbnbPricing? pricing,
  }) {
    return AirbnbListing(
      listingId: listingId ?? this.listingId,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      propertyType: propertyType ?? this.propertyType,
      roomType: roomType ?? this.roomType,
      maxGuests: maxGuests ?? this.maxGuests,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      beds: beds ?? this.beds,
      location: location ?? this.location,
      host: host ?? this.host,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photos: photos ?? this.photos,
      amenities: amenities ?? this.amenities,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      pricing: pricing ?? this.pricing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirbnbListing && other.listingId == listingId;
  }

  @override
  int get hashCode => listingId.hashCode;
}
