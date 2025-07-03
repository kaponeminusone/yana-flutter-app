import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // Importa el paquete para abrir archivos

// Vista de documentos para un vehículo
class DocsView extends StatelessWidget {
  final Map<String, dynamic> vehicleData;

  const DocsView({Key? key, required this.vehicleData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docs = vehicleData['docs'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Y', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          // Añadimos una URL de ejemplo al mapa de datos
          // En tu app, esta URL vendría de la API.
          final docWithUrl = {
            ...doc,
            'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', // URL de un PDF de ejemplo
            // Puedes añadir más URLs de diferentes tipos de archivos aquí para probar:
            // 'url_image': 'https://picsum.photos/300/200',
          };
          return _DocCard(doc: docWithUrl); // Usamos el nuevo widget de tarjeta
        },
      ),
    );
  }
}

// **Widget que representa la tarjeta de cada documento y maneja su estado.**
class _DocCard extends StatefulWidget {
  final Map<String, dynamic> doc;
  const _DocCard({Key? key, required this.doc}) : super(key: key);

  @override
  State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  bool _isDownloading = false; // Estado de la descarga
  double _downloadProgress = 0; // Progreso de la descarga
  bool _downloaded = false; // Si ya se descargó el archivo
  String? _filePath; // La ruta del archivo descargado en el dispositivo

  // **Función para descargar el archivo remoto**
  Future<void> _downloadAndOpenFile() async {
    final url = widget.doc['url'] as String;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final dio = Dio();
      // Obtener el directorio de caché para archivos temporales
      final dir = await getTemporaryDirectory();
      // Crear la ruta del archivo local
      final fileName = url.split('/').last;
      final savePath = '${dir.path}/$fileName';

      // Descargar el archivo con seguimiento de progreso
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloaded = true;
        _filePath = savePath;
      });

      // Abrir el archivo descargado
      await OpenFilex.open(_filePath!);

    } catch (e) {
      // Manejo de errores
      setState(() {
        _isDownloading = false;
        _downloaded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar el documento: $e')),
      );
      print('Error al descargar el archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final docName = widget.doc['name'] as String;
    final docStatus = widget.doc['status'] as Color;

    // Fechas de ejemplo
    final expiryDate = DateTime.now().add(Duration(days: 30));
    final uploadDate = DateTime.now().subtract(Duration(days: 5));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview del documento con InkWell para ser clickable
            InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              onTap: _isDownloading ? null : _downloadAndOpenFile, // Desactiva el tap mientras se descarga
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.25,
                  color: Colors.grey.shade200,
                  // Muestra un Stack con un indicador de carga o el icono
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ícono de preview
                      _isDownloading
                          ? CircularProgressIndicator(
                              value: _downloadProgress,
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            )
                          : const Icon(
                              Icons.picture_as_pdf,
                              size: 40,
                              color: Colors.grey,
                            ),
                      // Texto de progreso
                      if (_isDownloading)
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Información del documento (no clickable)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      docName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vence: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Subido: ${uploadDate.day}/${uploadDate.month}/${uploadDate.year}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            // Estado del documento
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: docStatus,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}