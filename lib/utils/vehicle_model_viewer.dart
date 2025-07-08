// lib/widgets/vehicle_model_viewer.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:o3d/o3d.dart'; // Asegúrate de que esta importación existe
import 'package:path_provider/path_provider.dart';

/// Muestra un modelo .glb dentro de un contenedor con controles de cámara,
/// cargado desde un asset local gracias a una copia a disco.
class VehicleModelViewer extends StatefulWidget {
  /// Ruta al asset .glb (p.ej. 'assets/3dmodels/nissan.glb')
  final String assetPath;

  /// ¿Gira automáticamente?
  final bool autoRotate;

  /// ¿Reproduce animaciones?
  final bool autoPlay;

  // Nuevas propiedades para la posición inicial de la cámara
  // CAMBIADO: Los tipos ahora son CameraTarget? y CameraOrbit?
  final CameraTarget? initialCameraTarget;
  final CameraOrbit? initialCameraOrbit;

  const VehicleModelViewer({
    Key? key,
    required this.assetPath,
    this.autoRotate = false,
    this.autoPlay = false,
    this.initialCameraTarget, // Añadir al constructor
    this.initialCameraOrbit,  // Añadir al constructor
  }) : super(key: key);

  @override
  State<VehicleModelViewer> createState() => _VehicleModelViewerState();
}

class _VehicleModelViewerState extends State<VehicleModelViewer> {
  late final O3DController _controller;
  String? _localFilePath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = O3DController();
    _copyAssetToLocal();
  }

  @override
  void dispose() {
    // No hay dispose() en O3DController, así que nada más
    super.dispose();
  }

  /// Copia el asset GLB a un archivo temporal en disco y guarda su ruta.
  Future<void> _copyAssetToLocal() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir    = await getApplicationDocumentsDirectory();
      final file   = File('${dir.path}/${widget.assetPath.split("/").last}');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      setState(() {
        _localFilePath = file.path;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error copiando asset: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    // Ya tenemos el path local al .glb, cargamos con file://
    return O3D(
      controller: _controller,
      src: 'file://$_localFilePath',
      autoRotate: widget.autoRotate,
      autoPlay: widget.autoPlay,
      cameraControls: true,
      ar: false,
      backgroundColor: Colors.transparent,
      // **** CAMBIADO: Asignar objetos CameraTarget y CameraOrbit ****
      cameraTarget: widget.initialCameraTarget,
      cameraOrbit: widget.initialCameraOrbit,
      // ************************************************************
    );
  }
}