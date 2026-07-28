import 'package:latlong2/latlong.dart';

class LocationFilter {
  LocationFilter({this.windowSize = 5});

  final int windowSize;

  final List<LatLng> _samples = [];

  LatLng filter(LatLng point) {
    _samples.add(point);

    if (_samples.length > windowSize) {
      _samples.removeAt(0);
    }

    double lat = 0;
    double lng = 0;

    for (final sample in _samples) {
      lat += sample.latitude;
      lng += sample.longitude;
    }

    return LatLng(lat / _samples.length, lng / _samples.length);
  }

  void clear() {
    _samples.clear();
  }
}
