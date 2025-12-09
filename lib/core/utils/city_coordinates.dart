import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// City coordinates for map markers
const Map<String, LatLng> cityCoordinates = {
  // Lebanon
  'Aley': LatLng(33.8075, 35.5997),
  'Baalbek': LatLng(34.0059, 36.2181),
  'Barouk': LatLng(33.6969, 35.7008),
  'Batroun': LatLng(34.2553, 35.6586),
  'Bcharre': LatLng(34.2506, 36.0128),
  'Beirut': LatLng(33.8886, 35.4955),
  'Bhamdoun': LatLng(33.8086, 35.6419),
  'Broummana': LatLng(33.8836, 35.6519),
  'Byblos': LatLng(34.1211, 35.6481),
  'Cedars': LatLng(34.2756, 36.0481),
  'Chouf': LatLng(33.6931, 35.5822),
  'Douma': LatLng(34.0333, 35.8000),
  'Ehden': LatLng(34.3000, 35.9833),
  'Faraya': LatLng(33.9667, 35.8333),
  'Hamat': LatLng(34.3, 35.65),
  'Hermel': LatLng(34.3925, 36.3889),
  'Jezzine': LatLng(33.5439, 35.5789),
  'Jounieh': LatLng(33.9806, 35.6178),
  'Kfardebian': LatLng(33.9833, 35.8333),
  'Laqlouq': LatLng(34.1167, 35.9500),
  'Mzaar': LatLng(34.0833, 35.9167),
  'Nabatieh': LatLng(33.3772, 35.4839),
  'Sidon': LatLng(33.5633, 35.3756),
  'Tripoli': LatLng(34.4367, 35.8497),
  'Tyre': LatLng(33.2733, 35.1933),
  'Zahle': LatLng(33.8469, 35.9019),
};

/// Lebanon center coordinates for default map view
const LatLng lebanonCenter = LatLng(33.8547, 35.8623);
const double defaultZoom = 8.0;

/// Get coordinates for a given city name
LatLng getCityCoordinates(String? cityName) {
  if (cityName == null || cityName.isEmpty) return lebanonCenter;

  // Try exact match first
  if (cityCoordinates.containsKey(cityName)) {
    return cityCoordinates[cityName]!;
  }

  // Try case-insensitive match
  final normalizedCity = cityName.trim().toLowerCase();
  final matchedKey = cityCoordinates.keys.firstWhere(
    (city) => city.toLowerCase() == normalizedCity,
    orElse: () => '',
  );

  return matchedKey.isNotEmpty ? cityCoordinates[matchedKey]! : lebanonCenter;
}

/// Get marker color based on price range
int getPriceColor(double price) {
  if (price < 100) return 0xFFFB8500; // Orange - cheap
  if (price < 300) return 0xFFeab308; // Yellow - medium
  return 0xFFef4444; // Red - expensive
}

/// Calculate map bounds to fit all listings
LatLngBounds? calculateBounds(List<LatLng> coordinates) {
  if (coordinates.isEmpty) return null;

  double minLat = double.infinity;
  double maxLat = double.negativeInfinity;
  double minLng = double.infinity;
  double maxLng = double.negativeInfinity;

  for (final coord in coordinates) {
    minLat = minLat > coord.latitude ? coord.latitude : minLat;
    maxLat = maxLat < coord.latitude ? coord.latitude : maxLat;
    minLng = minLng > coord.longitude ? coord.longitude : minLng;
    maxLng = maxLng < coord.longitude ? coord.longitude : maxLng;
  }

  // Add padding
  final latPadding = (maxLat - minLat) * 0.1;
  final lngPadding = (maxLng - minLng) * 0.1;

  return LatLngBounds(
    LatLng(minLat - latPadding, minLng - lngPadding),
    LatLng(maxLat + latPadding, maxLng + lngPadding),
  );
}
