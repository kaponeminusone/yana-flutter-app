// lib/views/home/tabs/qr_order_view.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:yana/providers/auth_provider.dart';

class QrOrderView extends StatefulWidget {
  /// El ID del vehículo para el que queremos generar el QR
  final String vehiculoId;
  const QrOrderView({Key? key, required this.vehiculoId}) : super(key: key);

  @override
  State<QrOrderView> createState() => _QrOrderViewState();
}

class _QrOrderViewState extends State<QrOrderView> {
  bool _loading = true;
  String? _errorMsg;
  Uint8List? _qrImage;
  Uri? _submissionUri;
  String? _fallbackCode;

  @override
  void initState() {
    super.initState();
    _fetchQrCode();
  }

  Future<void> _fetchQrCode() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final authToken = context.read<AuthProvider>().token; // tu JWT
      final url = Uri.parse('https://yana-gestorvehicular.onrender.com/api/qr/mantenimiento/${widget.vehiculoId}');
      final resp = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );
      if (resp.statusCode != 200) {
        throw Exception('Error ${resp.statusCode}: ${resp.body}');
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final imgData = data['qrCodeImage'] as String; // "data:image/png;base64,..."
      final workshopUrl = data['workshopSubmissionUrl'] as String;

      // Extraer sólo el base64 tras la coma
      final base64Part = imgData.split(',').last;
      final bytes = base64.decode(base64Part);

      // Extraer código de fallback: la query param "token"
      final uri = Uri.parse(workshopUrl);
      final code = uri.queryParameters['token'] ?? '';

      setState(() {
        _qrImage        = bytes;
        _submissionUri  = uri;
        _fallbackCode   = code;
        _loading        = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _loading  = false;
      });
    }
  }

  Future<void> _launchSubmission() async {
    if (_submissionUri == null) return;
    if (await canLaunchUrl(_submissionUri!)) {
      await launchUrl(_submissionUri!, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir ${_submissionUri.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Orden QR'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_errorMsg != null
                ? Center(child: Text('Error: $_errorMsg'))
                : Column(
                    children: [
                      // QR
                      if (_qrImage != null)
                        Container(
                          height: 250,
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_qrImage!, fit: BoxFit.contain),
                          ),
                        ),
                      const SizedBox(height: 24),

                      const Text(
                        'Si no puedes escanear el QR, ingresa el siguiente código en la web:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),

                      // URL pública (sin el token)
                      if (_submissionUri != null)
                        Text(
                          _submissionUri!.removeQuery().toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),

                      const SizedBox(height: 16),
                      // Código manual
                      if (_fallbackCode != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _fallbackCode!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),

                      const Spacer(),

                      ElevatedButton(
                        onPressed: _launchSubmission,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ir a la Web', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  )),
      ),
    );
  }
}

/// Extensión para quitar la query de un Uri
extension on Uri {
  Uri removeQuery() {
    return replace(queryParameters: {});
  }
}
