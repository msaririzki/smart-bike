class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

enum SimulationMode { loop, stopAtEnd, reset }

class MockRouteService {
  static const Map<String, LatLng> locationPresets = {
    'Kampus': LatLng(-8.5830, 116.1160),
    'Parkiran': LatLng(-8.5840, 116.1170),
    'Gerbang': LatLng(-8.5850, 116.1180),
    'Titik Demo 1': LatLng(-8.5860, 116.1190),
    'Titik Demo 2': LatLng(-8.5875, 116.1205),
  };

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

  void next({SimulationMode mode = SimulationMode.loop}) {
    if (hasNext) {
      _currentIndex++;
    } else {
      if (mode == SimulationMode.loop) {
        _currentIndex = 0;
      } else if (mode == SimulationMode.reset) {
        _currentIndex = 0;
        // The caller should stop the timer when it sees currentIndex reset if they want it to stop
      }
      // stopAtEnd: do nothing, just stay at current index
    }
  }

  void reset() {
    _currentIndex = 0;
  }
}
