import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

import '../../models/vehiculo_model.dart';
import '../../models/obligacion_legal_model.dart';
import '../../providers/obligacion_legal_provider.dart';
// Asegúrate de tener un provider para el baseUrl de Dio o pásalo de alguna manera
// Por ejemplo, si tu ApiService provee Dio, puedes hacer un Provider.of<ApiService>(context).dio
// O, si tienes un EnvironmentConfigProvider con la baseUrl
// import '../../providers/environment_config_provider.dart';

class DocsView extends StatefulWidget {
  final VehiculoModel vehiculo;
  final List<ObligacionLegalModel>? obligaciones; // Opcional: si ya están cargadas

  const DocsView({Key? key, required this.vehiculo, this.obligaciones}) : super(key: key);

  @override
  State<DocsView> createState() => _DocsViewState();
}

class _DocsViewState extends State<DocsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final obligacionProvider = Provider.of<ObligacionLegalProvider>(context, listen: false);
      // Solo cargar si las obligaciones no se pasaron al constructor o si el provider no ha cargado aún
      if (widget.obligaciones == null && obligacionProvider.obligaciones.isEmpty) {
        obligacionProvider.fetchObligacionesByVehiculoId(widget.vehiculo.id);
      }
    });
  }

  /// Genera una lista de ObligacionLegalModel de ejemplo (fakes) para mostrar en caso de error.
  List<ObligacionLegalModel> _fakeObligaciones() {
    return [
      ObligacionLegalModel.fromJson({
        "id": "fake-001",
        "vehiculoId": widget.vehiculo.id,
        "nombre": "SOAT (Ejemplo)",
        "tipo": "Seguro",
        "fechaEmision": "2024-01-01T00:00:00Z",
        "fechaVencimiento": "2025-01-01T00:00:00Z", // Vigente
        "archivoPath": "documentos/dummy-soat.pdf", // Ruta relativa o solo nombre si es dummy
        "costo": 500000.0,
        "notas": "Este es un documento de ejemplo SOAT. Su URL es un PDF dummy."
      }),
      ObligacionLegalModel.fromJson({
        "id": "fake-002",
        "vehiculoId": widget.vehiculo.id,
        "nombre": "Revisión Técnico-Mecánica (Ejemplo)",
        "tipo": "Certificado",
        "fechaEmision": "2023-03-10T00:00:00Z",
        "fechaVencimiento": "2024-03-10T00:00:00Z", // Vencida
        "archivoPath": "documentos/dummy-tecnomecanica.pdf",
        "costo": 200000.0,
        "notas": "Este es un documento de ejemplo de Revisión. Su URL es un PDF dummy."
      }),
      ObligacionLegalModel.fromJson({
        "id": "fake-003",
        "vehiculoId": widget.vehiculo.id,
        "nombre": "Tarjeta de Propiedad (Ejemplo)",
        "tipo": "Identificación",
        "fechaEmision": "2022-05-20T00:00:00Z",
        "fechaVencimiento": null, // Sin vencimiento
        "archivoPath": "documentos/dummy-tarjeta-propiedad.pdf",
        "costo": 0.0,
        "notas": "Este es un documento de ejemplo de Tarjeta de Propiedad. Su URL es un PDF dummy."
      }),
      ObligacionLegalModel.fromJson({
        "id": "fake-004",
        "vehiculoId": widget.vehiculo.id,
        "nombre": "Seguro Contractual (Ejemplo)",
        "tipo": "Seguro",
        "fechaEmision": "2024-06-15T00:00:00Z",
        "fechaVencimiento": "2024-07-20T00:00:00Z", // Próxima a vencer
        "archivoPath": "documentos/dummy-seguro.pdf",
        "costo": 300000.0,
        "notas": "Este es un documento de ejemplo de Seguro. Su URL es un PDF dummy."
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final obligacionProvider = context.watch<ObligacionLegalProvider>();

    // Determina qué lista de obligaciones mostrar
    List<ObligacionLegalModel> displayObligations;
    bool hasError = obligacionProvider.errorMessage != null;

    if (hasError) {
      // Si hay error, muestra los datos fakes
      displayObligations = _fakeObligaciones();
    } else {
      // Si no hay error, usa las obligaciones reales (o las pasadas al constructor)
      displayObligations = widget.obligaciones ?? obligacionProvider.obligaciones;
      // Filtra las obligaciones reales para solo mostrar las que tienen un archivoPath
      displayObligations = displayObligations
          .where((o) => o.archivoPath != null && o.archivoPath!.isNotEmpty)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.vehiculo.marca} ${widget.vehiculo.modelo} - Documentos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.white,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          // Estado de carga inicial o cuando se está recargando
          if (obligacionProvider.isLoading && !hasError) { // Solo muestra loading si NO hay error
            return const Center(child: CircularProgressIndicator());
          }

          // Mensaje de error (si existe) que se mostrará encima de la lista de fakes
          if (hasError) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar documentos: ${obligacionProvider.errorMessage!}. Mostrando datos de ejemplo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          obligacionProvider.clearErrorMessage(); // Limpia el error
                          obligacionProvider.fetchObligacionesByVehiculoId(widget.vehiculo.id); // Reintenta
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          textStyle: const TextStyle(fontSize: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder( // Cambiado a GridView.builder
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Dos tarjetas por fila
                      crossAxisSpacing: 16.0, // Espacio horizontal entre tarjetas
                      mainAxisSpacing: 16.0, // Espacio vertical entre tarjetas
                      childAspectRatio: 0.75, // Ajusta este valor para controlar la proporción (ancho/alto) de la tarjeta.
                                             // 0.75 significa que el alto es ~1.33 veces el ancho.
                    ),
                    itemCount: displayObligations.length,
                    itemBuilder: (context, index) {
                      final obligacion = displayObligations[index];
                      return _DocCard(obligacion: obligacion);
                    },
                  ),
                ),
              ],
            );
          }

          // Estado vacío: No hay documentos después de cargar (sin error y lista vacía)
          if (displayObligations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay documentos legales asociados a este vehículo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verifica la información en el sistema o añade nuevos documentos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Mostrar la lista de documentos reales en una cuadrícula
          return GridView.builder( // Cambiado a GridView.builder
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Dos tarjetas por fila
              crossAxisSpacing: 16.0, // Espacio horizontal entre tarjetas
              mainAxisSpacing: 16.0, // Espacio vertical entre tarjetas
              childAspectRatio: 0.75, // Ajusta este valor para controlar la proporción (ancho/alto) de la tarjeta.
                                     // 0.75 significa que el alto es ~1.33 veces el ancho.
            ),
            itemCount: displayObligations.length,
            itemBuilder: (context, index) {
              final obligacion = displayObligations[index];
              return _DocCard(obligacion: obligacion);
            },
          );
        },
      ),
    );
  }
}

// **Widget que representa la tarjeta de cada documento y maneja su estado.**
class _DocCard extends StatefulWidget {
  final ObligacionLegalModel obligacion;
  const _DocCard({Key? key, required this.obligacion}) : super(key: key);

  @override
  State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _filePath; // Almacena la ruta del archivo descargado

  // **NUEVA URL de PDF dummy más confiable para pruebas**
  static const String _dummyPdfUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  Future<void> _downloadAndOpenFile() async {
    bool isFakeDoc = widget.obligacion.id.startsWith('fake-');
    String fileUrlToDownload;

    if (isFakeDoc) {
      fileUrlToDownload = _dummyPdfUrl;
    } else {
      final dio = Provider.of<Dio>(context, listen: false);
      final String baseUrl = dio.options.baseUrl;

      if (widget.obligacion.archivoPath == null || widget.obligacion.archivoPath!.isEmpty) {
        _showSnackBar(context, 'Este documento no tiene una URL de descarga válida.', Colors.orange);
        return;
      }
      // Construir la URL completa, manejando casos de rutas relativas/absolutas
      if (widget.obligacion.archivoPath!.startsWith('http://') || widget.obligacion.archivoPath!.startsWith('https://')) {
        fileUrlToDownload = widget.obligacion.archivoPath!; // Ya es una URL completa
      } else {
        fileUrlToDownload = "$baseUrl/${widget.obligacion.archivoPath!}";
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      // Usa una nueva instancia de Dio para la descarga por si la principal tiene interceptores
      // que no apliquen a descargas de URLs externas (como el dummy URL).
      final dioForDownload = Dio();
      final dir = await getTemporaryDirectory();
      
      // Asegurarse de que el nombre del archivo sea seguro y tenga extensión
      String fileName = Uri.parse(fileUrlToDownload).pathSegments.last;
      if (!fileName.contains('.')) {
        fileName = '$fileName.pdf'; // Añadir una extensión predeterminada si no la tiene
      }
      final savePath = '${dir.path}/${widget.obligacion.nombre}_${fileName.hashCode}.pdf'; // Nombre único

      await dioForDownload.download(
        fileUrlToDownload,
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
        _filePath = savePath; // Guarda la ruta del archivo descargado
      });

      await OpenFilex.open(_filePath!);
      _showSnackBar(context, 'Documento descargado y abierto con éxito!', Colors.green);

    } on DioException catch (e) {
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Tiempo de espera agotado. Verifica tu conexión a internet.';
      } else if (e.response != null) {
        errorMessage = 'Servidor: ${e.response?.statusCode} - ${e.response?.statusMessage ?? 'Error desconocido'}';
        if (e.response?.statusCode == 404) {
          errorMessage = 'El documento no se encontró en el servidor (URL: ${fileUrlToDownload}).';
        }
      } else {
        errorMessage = 'Error de red o desconocido: ${e.message}';
      }
      _showSnackBar(context, 'Error al descargar el documento: $errorMessage', Theme.of(context).colorScheme.error);
      print('Error al descargar el archivo: $errorMessage');
      setState(() { _isDownloading = false; });
    } catch (e) {
      _showSnackBar(context, 'Error inesperado al descargar: $e', Theme.of(context).colorScheme.error);
      print('Error inesperado al descargar: $e');
      setState(() { _isDownloading = false; });
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getStatusColor(DateTime? fechaVencimiento) {
    if (fechaVencimiento == null) {
      return Colors.grey; // Sin fecha de vencimiento
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDate = DateTime(fechaVencimiento.year, fechaVencimiento.month, fechaVencimiento.day);

    if (expirationDate.isBefore(today)) {
      return Colors.red.shade700; // Vencido
    }
    if (expirationDate.difference(today).inDays <= 30) {
      return Colors.orange.shade700; // Vence en menos de 30 días
    }
    return Colors.green.shade700; // Vigente
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return 'N/A';
    // Usamos el locale 'es' para asegurar el formato de mes en español
    return DateFormat('dd MMM yyyy', 'es').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final obligacion = widget.obligacion;
    final docName = obligacion.nombre;
    final docStatusColor = _getStatusColor(obligacion.fechaVencimiento);

    return Card(
      margin: EdgeInsets.zero, // El margin se maneja en el GridView
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Bordes sutilmente redondeados
      ),
      elevation: 2, // Sombra sutil
      child: InkWell(
        onTap: _isDownloading ? null : _downloadAndOpenFile,
        borderRadius: BorderRadius.circular(10), // Coincidir con el borde de la tarjeta
        child: Column( // Columna principal para el layout vertical
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar los hijos horizontalmente
          children: [
            // Sección de Preview (arriba)
            // Usa AspectRatio para que la altura del preview sea proporcional a su ancho.
            // aspectRatio: 1.5 significa ancho es 1.5 veces el alto, lo que da una relación 3:2
            // Esto hace que el preview ocupe una parte significativa de la tarjeta (aprox 1/2 del ancho de la vista y ~1/4 del alto de la tarjeta)
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08), // Fondo ligero con color primario
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), // Solo las esquinas superiores redondeadas
                ),
                child: Center(
                  child: _isDownloading
                      ? CircularProgressIndicator(
                          value: _downloadProgress,
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        )
                      : Icon(
                          Icons.picture_as_pdf, // Icono de PDF
                          size: 48, // Icono más grande para la tarjeta vertical
                          color: Theme.of(context).primaryColor,
                        ),
                ),
              ),
            ),

            // Sección de Detalles del Documento (abajo)
            Expanded( // Permite que los detalles ocupen el espacio restante
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Padding interno para el texto
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye el espacio entre elementos
                  children: [
                    Text(
                      docName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column( // Agrupa tipo y vencimiento
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Tipo: ${obligacion.tipo ?? 'N/A'}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Row( // Fila para la fecha de vencimiento y el punto de estado
                          children: [
                            Text(
                              'Vence: ${_getFormattedDate(obligacion.fechaVencimiento)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: docStatusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8), // Espacio entre texto y punto
                            Container( // Punto indicador de estado
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: docStatusColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5), // Borde blanco pequeño
                                boxShadow: [ // Sombra sutil para el punto
                                  BoxShadow(
                                    color: docStatusColor.withOpacity(0.3),
                                    blurRadius: 3,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}