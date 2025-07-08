import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Muestra un Google Calendar embebido dentro de un WebView.
class GoogleCalendarWidget extends StatefulWidget {
  /// La URL completa de tu calendario embebido.
  final String calendarUrl;

  /// Altura del widget (por defecto 1/3 de la pantalla).
  final double? height;

  const GoogleCalendarWidget({
    Key? key,
    required this.calendarUrl,
    this.height,
  }) : super(key: key);

  @override
  State<GoogleCalendarWidget> createState() => _GoogleCalendarWidgetState();
}

class _GoogleCalendarWidgetState extends State<GoogleCalendarWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.calendarUrl));
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? MediaQuery.of(context).size.height / 3;
    return SizedBox(
      height: h,
      child: WebViewWidget(controller: _controller),
    );
  }
}
