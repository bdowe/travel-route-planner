// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'airbnb_listing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AirbnbListingLocation _$AirbnbListingLocationFromJson(
        Map<String, dynamic> json) =>
    AirbnbListingLocation(
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$AirbnbListingLocationToJson(
        AirbnbListingLocation instance) =>
    <String, dynamic>{
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

AirbnbHost _$AirbnbHostFromJson(Map<String, dynamic> json) => AirbnbHost(
      name: json['name'] as String,
      avatar: json['avatar'] as String,
    );

Map<String, dynamic> _$AirbnbHostToJson(AirbnbHost instance) =>
    <String, dynamic>{
      'name': instance.name,
      'avatar': instance.avatar,
    };

AirbnbPhoto _$AirbnbPhotoFromJson(Map<String, dynamic> json) => AirbnbPhoto(
      url: json['url'] as String,
      caption: json['caption'] as String,
    );

Map<String, dynamic> _$AirbnbPhotoToJson(AirbnbPhoto instance) =>
    <String, dynamic>{
      'url': instance.url,
      'caption': instance.caption,
    };

AirbnbPricing _$AirbnbPricingFromJson(Map<String, dynamic> json) =>
    AirbnbPricing(
      nightlyRate: (json['nightly_rate'] as num).toDouble(),
      nights: (json['nights'] as num).toInt(),
      cleaningFee: (json['cleaning_fee'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$AirbnbPricingToJson(AirbnbPricing instance) =>
    <String, dynamic>{
      'nightly_rate': instance.nightlyRate,
      'nights': instance.nights,
      'cleaning_fee': instance.cleaningFee,
      'service_fee': instance.serviceFee,
      'total': instance.total,
      'currency': instance.currency,
    };

AirbnbListing _$AirbnbListingFromJson(Map<String, dynamic> json) =>
    AirbnbListing(
      listingId: json['listing_id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      propertyType: json['property_type'] as String,
      roomType: json['room_type'] as String,
      maxGuests: (json['max_guests'] as num).toInt(),
      bedrooms: (json['bedrooms'] as num).toInt(),
      bathrooms: (json['bathrooms'] as num).toDouble(),
      beds: (json['beds'] as num).toInt(),
      location: AirbnbListingLocation.fromJson(
          json['location'] as Map<String, dynamic>),
      host: AirbnbHost.fromJson(json['host'] as Map<String, dynamic>),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as num).toInt(),
      photos: (json['photos'] as List<dynamic>)
          .map((e) => AirbnbPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
      amenities:
          (json['amenities'] as List<dynamic>).map((e) => e as String).toList(),
      checkIn: json['check_in'] as String,
      checkOut: json['check_out'] as String,
      pricing: AirbnbPricing.fromJson(json['pricing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AirbnbListingToJson(AirbnbListing instance) =>
    <String, dynamic>{
      'listing_id': instance.listingId,
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'property_type': instance.propertyType,
      'room_type': instance.roomType,
      'max_guests': instance.maxGuests,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'beds': instance.beds,
      'location': instance.location,
      'host': instance.host,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
      'photos': instance.photos,
      'amenities': instance.amenities,
      'check_in': instance.checkIn,
      'check_out': instance.checkOut,
      'pricing': instance.pricing,
    };
