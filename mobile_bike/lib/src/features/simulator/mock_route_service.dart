class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class MockRouteService {
  static const List<LatLng> mockRoute = [
    LatLng(-8.5830, 116.1160), // Dekat Kampus 
    LatLng(-8.5835, 116.1165),
    LatLng(-8.5840, 116.1170),
    LatLng(-8.5845, 116.1175),
    LatLng(-8.5850, 116.1180),
    LatLng(-8.5855, 116.1185),
    LatLng(-8.5860, 116.1190),
    LatLng(-8.5865, 116.1195),
    LatLng(-8.5870, 116.1200),
    LatLng(-8.5875, 116.1205),
  ];

  int _currentIndex = 0;

  LatLng get currentPoint => mockRoute[_currentIndex];
  int get currentIndex => _currentIndex;
  int get totalPoints => mockRoute.length;

  bool get hasNext => _currentIndex < mockRoute.length - 1;

  void next() {
    if (hasNext) {
      _currentIndex++;
    } else {
      _currentIndex = 0; // Loop back or stop
    }
  }

  void reset() {
    _currentIndex = 0;
  }
}
