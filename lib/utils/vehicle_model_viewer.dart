// lib/widgets/vehicle_model_viewer.dart
import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';

/// Muestra un modelo .glb dentro de un contenedor con controles de cámara.
class VehicleModelViewer extends StatefulWidget {
  /// Ruta al asset .glb
  final String assetPath;

  /// ¿Gira automáticamente?
  final bool autoRotate;

  /// ¿Reproduce animaciones?
  final bool autoPlay;

  const VehicleModelViewer({
    Key? key,
    required this.assetPath,
    this.autoRotate = true,
    this.autoPlay = false,
  }) : super(key: key);

  @override
  State<VehicleModelViewer> createState() => _VehicleModelViewerState();
}

class _VehicleModelViewerState extends State<VehicleModelViewer> {
  late final O3DController _controller;

  @override
  void initState() {
    super.initState();
    _controller = O3DController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return O3D(
      controller: _controller,
      src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      autoRotate: true,
      cameraControls: true,
      backgroundColor: Colors.white,
    );

  }
}
