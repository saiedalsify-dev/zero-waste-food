import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  static const LatLng _cairoLocation = LatLng(30.0444, 31.2357);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _cairoLocation,
    zoom: 13,
  );

  static const Marker _cairoMarker = Marker(
    markerId: MarkerId('cairo_marker'),
    position: _cairoLocation,
    infoWindow: InfoWindow(title: 'Cairo'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: <Marker>{_cairoMarker},
        myLocationButtonEnabled: false,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
