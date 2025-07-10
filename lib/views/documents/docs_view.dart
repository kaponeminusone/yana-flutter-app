// lib/views/documents/docs_view.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

import '../../models/obligacion_legal_model.dart';
import '../../models/vehiculo_model.dart';
import '../../providers/obligacion_legal_provider.dart';

class DocsView extends StatefulWidget {
  final VehiculoModel vehiculo;
  final List<ObligacionLegalModel>? obligaciones;

  const DocsView({Key? key, required this.vehiculo, this.obligaciones}) : super(key: key);

  @override
  State<DocsView> createState() => _DocsViewState();
}

class _DocsViewState extends State<DocsView> {
  @override
  void initState() {
    super.initState();
    _fetchObligations(); // Call a method to fetch obligations
  }

  void _fetchObligations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ObligacionLegalProvider>(context, listen: false);
      if (widget.obligaciones == null && prov.obligaciones.isEmpty) {
        prov.fetchObligacionesByVehiculoId(widget.vehiculo.id);
      }
    });
  }

  List<ObligacionLegalModel> _fakeObligaciones() => [
    ObligacionLegalModel.fromJson({
      'id': 'fake-001',
      'vehiculoId': widget.vehiculo.id,
      'nombre': 'SOAT (Seguro Obligatorio de Accidentes de Tránsito)',
      'tipo': 'Seguro Obligatorio',
      'descripcion': 'Póliza de seguro obligatoria para cubrir daños corporales a personas en accidentes de tránsito.',
      'fechaVencimiento': '2025-06-30',
      'documentoPath': 'documentos/dummy-soat.pdf', // Example path
    }),
    ObligacionLegalModel.fromJson({
      'id': 'fake-002',
      'vehiculoId': widget.vehiculo.id,
      'nombre': 'Revisión Técnico Mecánica y de Emisiones Contaminantes (RTM)',
      'tipo': 'Inspección Vehicular',
      'descripcion': 'Certificado que valida las condiciones mecánicas y ambientales del vehículo.',
      'fechaVencimiento': '2024-07-01', // Example of an expired document
      'documentoPath': 'documentos/dummy-rtm.pdf', // Example path
    }),
    ObligacionLegalModel.fromJson({
      'id': 'fake-003',
      'vehiculoId': widget.vehiculo.id,
      'nombre': 'Impuesto de Rodamiento Anual del Vehículo',
      'tipo': 'Impuesto Vehicular',
      'descripcion': 'Impuesto que deben pagar los propietarios de vehículos anualmente.',
      'fechaVencimiento': '2025-08-15', // Example of an upcoming document
      'documentoPath': null, // Example with null document path
    }),
     ObligacionLegalModel.fromJson({
      'id': 'fake-004',
      'vehiculoId': widget.vehiculo.id,
      'nombre': 'Licencia de Tránsito',
      'tipo': 'Documento Identificación Vehicular',
      'descripcion': 'Documento público que identifica un vehículo automotor y lo autoriza para transitar.',
      'fechaVencimiento': null, // Example with null date
      'documentoPath': 'documentos/dummy-licencia.pdf',
    }),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ObligacionLegalProvider>();
    final hasError = prov.errorMessage != null;
    final obligations = hasError
        ? _fakeObligaciones() // Show fake data on error
        : (widget.obligaciones ?? prov.obligaciones);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text('${widget.vehiculo.marca} ${widget.vehiculo.modelo}'),
        centerTitle: true,
      ),
      body: prov.isLoading && !hasError && obligations.isEmpty // Show loading only if no error and no obligations yet
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _ErrorView(
                  errorMessage: prov.errorMessage!,
                  onRetry: _fetchObligations,
                )
              : obligations.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No hay documentos legales disponibles para este vehículo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65, // Adjusted for more vertical space for descriptions
                      ),
                      itemCount: obligations.length,
                      itemBuilder: (_, i) => _DocCard(obligacion: obligations[i]),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({Key? key, required this.errorMessage, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              'Error al cargar documentos: $errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mostrando datos de ejemplo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Background color
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatefulWidget {
  final ObligacionLegalModel obligacion;
  const _DocCard({Key? key, required this.obligacion}) : super(key: key);

  @override
  State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  bool _loading = false;
  double _progress = 0;
  String? _path;
  static const dummyUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  Future<void> _open() async {
    final isFake = widget.obligacion.id.startsWith('fake-');
    final String? docPath = widget.obligacion.documentoPath;
    final url = isFake ? dummyUrl : (docPath != null && docPath.isNotEmpty ? docPath : null);

    if (url == null || url.isEmpty) {
      _snack('No hay URL válida para abrir este documento.', Colors.orange);
      return;
    }

    setState(() {
      _loading = true;
      _progress = 0;
    });
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory();
      String name;
      try {
        name = Uri.parse(url).pathSegments.last;
        if (name.isEmpty || !name.contains('.')) {
          name = '${widget.obligacion.nombre?.replaceAll(' ', '_') ?? 'documento'}.pdf';
        }
      } catch (e) {
        name = '${widget.obligacion.nombre?.replaceAll(' ', '_') ?? 'documento'}.pdf';
      }

      final save = '${dir.path}/${name.hashCode}.pdf';

      await dio.download(url, save, onReceiveProgress: (r, t) {
        if (t > 0) setState(() => _progress = r / t);
      });
      setState(() {
        _loading = false;
        _path = save;
      });
      await OpenFilex.open(_path!);
      _snack('Documento abierto', Colors.green);
    } catch (e) {
      _snack('Error al abrir documento: ${e.toString()}', Colors.red);
      setState(() {
        _loading = false;
      });
    }
  }

  void _snack(String m, Color c) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  Color _color(DateTime? d) {
    if (d == null) return Colors.grey;
    final now = DateTime.now();
    final exp = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);

    if (exp.isBefore(today)) return Colors.red;
    if (exp.difference(today).inDays <= 30) return Colors.orange;
    return Colors.green;
  }

  String _fmt(DateTime? d) => d == null ? 'N/A' : DateFormat('dd MMMM yyyy', 'es').format(d);

  @override
  Widget build(BuildContext context) {
    final o = widget.obligacion;
    final c = _color(o.fechaVencimiento);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: InkWell(
        onTap: _loading ? null : _open,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4, // Takes more vertical space for the PDF icon
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Center(
                  child: _loading
                      ? CircularProgressIndicator(value: _progress)
                      : Icon(Icons.picture_as_pdf, size: 70, color: Theme.of(context).primaryColor), // Larger icon
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                o.nombre ?? 'Sin Nombre',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (o.tipo != null && o.tipo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  o.tipo!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (o.descripcion != null && o.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(
                  o.descripcion!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3, // Allow more lines for description
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(), // Pushes the following content to the bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Adjusted padding for bottom content
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vence: ${_fmt(o.fechaVencimiento)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}