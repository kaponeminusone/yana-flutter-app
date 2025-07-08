import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart'; // Asegúrate de tener dio en tu pubspec.yaml
import 'package:google_fonts/google_fonts.dart'; // Importar Google Fonts

import 'package:yana/views/maintenance/edit_maintenance_view.dart';

// Asegúrate de que estas rutas sean correctas para tu proyecto
import '../../../providers/mantenimiento_provider.dart';
import '../../../models/mantenimiento_model.dart';
// Si tienes un modelo Vehiculo aparte, asegúrate de importarlo también
// import '../../../models/vehiculo_model.dart';

class MaintenanceTab extends StatefulWidget {
  const MaintenanceTab({Key? key}) : super(key: key);

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  DateTime? _filterDate;
  String? _filterType;
  String? _filterPlate;

  MantenimientoModel? _featuredMantenimiento; // El mantenimiento seleccionado para el preview

  final TextEditingController _typeFilterController = TextEditingController();
  final TextEditingController _plateFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Establecer el locale por defecto para Intl (para formatos de fecha)
    Intl.defaultLocale = 'es';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar los mantenimientos al iniciar la vista
      Provider.of<MantenimientoProvider>(context, listen: false).fetchMantenimientos().then((_) {
        // Una vez que los mantenimientos se cargan, establece el primero como destacado
        if (context.read<MantenimientoProvider>().mantenimientos.isNotEmpty) {
          _updateFeaturedMantenimiento(context.read<MantenimientoProvider>().mantenimientos[0]);
        }
      });
    });
  }

  @override
  void dispose() {
    _typeFilterController.dispose();
    _plateFilterController.dispose();
    super.dispose();
  }

  // Función para actualizar el mantenimiento destacado
  void _updateFeaturedMantenimiento(MantenimientoModel mantenimiento) {
    setState(() {
      _featuredMantenimiento = mantenimiento;
    });
  }

  List<MantenimientoModel> _applyFilters(List<MantenimientoModel> mantenimientos) {
    List<MantenimientoModel> filteredList = mantenimientos.where((mantenimiento) {
      final matchDate = _filterDate == null ||
          DateFormat.yMd().format(mantenimiento.fecha) == DateFormat.yMd().format(_filterDate!);

      final matchType =
          _filterType == null || mantenimiento.tipo.toLowerCase().contains(_filterType!.toLowerCase());

      final matchPlate = _filterPlate == null ||
          (mantenimiento.vehiculo?.placa?.toLowerCase() ?? '').contains(_filterPlate!.toLowerCase());

      return matchDate && matchType && matchPlate;
    }).toList();

    // Ordenar la lista filtrada basándose en fechaVencimiento
    filteredList.sort((a, b) {
      // Función auxiliar para determinar si una fecha es pasada (solo fecha, no hora)
      bool isPast(DateTime? date) {
        if (date == null) return false;
        final now = DateTime.now();
        // Compara solo las partes de la fecha (año, mes, día)
        return date.year < now.year ||
            (date.year == now.year && date.month < now.month) ||
            (date.year == now.year && date.month == now.month && date.day < now.day);
      }

      final aVencimiento = a.fechaVencimiento;
      final bVencimiento = b.fechaVencimiento;

      final aIsPast = isPast(aVencimiento);
      final bIsPast = isPast(bVencimiento);

      // Los mantenimientos sin fecha de vencimiento van al final
      if (aVencimiento == null && bVencimiento == null) return 0;
      if (aVencimiento == null) return 1; // 'a' es null, va después
      if (bVencimiento == null) return -1; // 'b' es null, 'a' va antes

      // Las fechas pasadas van después de las fechas futuras/actuales
      if (aIsPast && !bIsPast) return 1;
      if (!aIsPast && bIsPast) return -1;

      // Si ambos son pasados o ambos son futuros/actuales, ordenar por fecha normalmente (ascendente)
      return aVencimiento!.compareTo(bVencimiento!);
    });

    // Lógica para actualizar _featuredMantenimiento
    // Si el mantenimiento destacado ya no está en la lista filtrada, selecciona el primero de la nueva lista
    if (_featuredMantenimiento != null && !filteredList.contains(_featuredMantenimiento)) {
      _featuredMantenimiento = filteredList.isNotEmpty ? filteredList.first : null;
    } else if (_featuredMantenimiento == null && filteredList.isNotEmpty) {
      // Si no hay destacado y la lista no está vacía, destaca el primero
      _featuredMantenimiento = filteredList.first;
    } else if (filteredList.isEmpty) {
      // Si la lista está vacía, no hay nada que destacar
      _featuredMantenimiento = null;
    }

    return filteredList;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 años atrás
      lastDate: DateTime.now().add(const Duration(days: 365)), // 1 año adelante
    );
    if (d != null) {
      setState(() {
        _filterDate = d;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MantenimientoProvider>(
      builder: (context, mantenimientoProvider, child) {
        final List<MantenimientoModel> allMantenimientos = mantenimientoProvider.mantenimientos;

        // Estado de carga inicial (si no hay mantenimientos y está cargando)
        if (mantenimientoProvider.isLoading && allMantenimientos.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, // Color primario
            ),
          );
        }

        // Estado de error (replicado del VehiclesTab)
        if (mantenimientoProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, color: Colors.grey[600], size: 80), // Ícono de error más neutral
                  const SizedBox(height: 24),
                  Text(
                    'Parece que hay un problema de conexión o el servidor no responde.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18, // Tamaño de fuente ligeramente más grande
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Por favor, verifica tu conexión a internet o intenta de nuevo más tarde.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (mantenimientoProvider.errorMessage != null && mantenimientoProvider.errorMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Detalles: ${mantenimientoProvider.errorMessage}', // Mostrar detalles técnicos para depuración
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      mantenimientoProvider.clearErrorMessage();
                      mantenimientoProvider.fetchMantenimientos();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary, // Usa el color primario del tema
                      foregroundColor: Theme.of(context).colorScheme.onPrimary, // Color del texto sobre el primario
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh), // Ícono de refrescar
                    label: Text(
                      'Reintentar Carga',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Si _featuredMantenimiento no es nulo, obtenemos sus obligaciones cargadas por el provider
        final List<MantenimientoModel> filteredMantenimientos = _applyFilters(allMantenimientos);

        // Asegurarse de que _featuredMantenimiento esté inicializado al menos con el primer mantenimiento
        if (_featuredMantenimiento == null && filteredMantenimientos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateFeaturedMantenimiento(filteredMantenimientos[0]);
          });
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, // Color primario
            ),
          );
        }

        // Estado vacío (si no hay mantenimientos y no está cargando)
        if (allMantenimientos.isEmpty && !mantenimientoProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No tienes mantenimientos registrados.',
                  style: GoogleFonts.poppins(
                    fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Usa el botón "+" para agregar uno.',
                  style: GoogleFonts.poppins(
                    fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildPreviewCard(context, filteredMantenimientos),
            const SizedBox(height: 20),
            _buildFilterWidgets(context),
            const SizedBox(height: 18),
            Expanded(
              child: filteredMantenimientos.isEmpty
                  ? Center(
                      child: Text(
                        'No hay resultados para los filtros aplicados.',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 0), // Eliminar padding para que el Dismissible se vea mejor
                      itemCount: filteredMantenimientos.length,
                      itemBuilder: (ctx, i) {
                        final mantenimiento = filteredMantenimientos[i];
                        return Column(
                          children: [
                            _buildMaintenanceListItem(context, mantenimiento, mantenimientoProvider),
                            // Línea divisora entre elementos de la lista, pero dentro del padding del Dismissible
                             const Divider(height: 1, thickness: 1, color: Colors.grey),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildPreviewCard(BuildContext context, List<MantenimientoModel> filteredMantenimientos) {
    final String baseUrl = Provider.of<Dio>(context, listen: false).options.baseUrl;

    if (_featuredMantenimiento == null) {
      return Container(
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(20),
          ),
        ),
        height: 200, // Altura fija para el card cuando no hay preview
        child: Center(
          child: Text(
            filteredMantenimientos.isEmpty
                ? 'No hay mantenimientos para mostrar en el preview.'
                : 'Selecciona un mantenimiento de la lista para ver su preview.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: IntrinsicHeight( // Ajusta la altura al contenido más alto de la fila
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los hijos para que tengan la misma altura
          children: [
            // Sección izquierda: Icono/Imagen de la factura
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30), // Asegúrate de que coincida con el borderRadius del contenedor padre
              ),
              child: Container(
                width: 120, // Ancho fijo para la imagen/icono
                height: 230,
                color: Colors.grey.shade300,
                child: _featuredMantenimiento!.facturaPath != null &&
                        _featuredMantenimiento!.facturaPath!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: "$baseUrl/${_featuredMantenimiento!.facturaPath!}",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
                        errorWidget: (context, url, error) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
                              Text(
                                'No image',
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade600),
                      ),
              ),
            ),
            const SizedBox(width: 20),
            // Sección derecha: Detalles del mantenimiento
            Expanded(
              
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _featuredMantenimiento!.tipo,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary, // Color primario
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vehículo: ${_featuredMantenimiento!.vehiculo?.placa ?? 'N/A'} '
                      '(${_featuredMantenimiento!.vehiculo?.marca ?? 'Marca Desconocida'} '
                      '${_featuredMantenimiento!.vehiculo?.modelo ?? 'Modelo Desconocido'})',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kilometraje: ${_featuredMantenimiento!.kilometraje} km',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Costo: \$${_featuredMantenimiento!.costo.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fecha: ${DateFormat('dd MMM', 'es').format(_featuredMantenimiento!.fecha)}', // Fecha de mantenimiento original
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    if (_featuredMantenimiento!.fechaVencimiento != null)
                      Text(
                        'Próx. Mantenimiento: ${DateFormat('dd MMM', 'es').format(_featuredMantenimiento!.fechaVencimiento!)}', // Próxima fecha de mantenimiento
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Obs: ${_featuredMantenimiento!.descripcion}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 15)
                  ],
                ),
                
              ),
              
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterWidgets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Campo de Fecha
          Expanded(
            child: TextField(
              readOnly: true, // Hace que el TextField no sea editable directamente
              controller: TextEditingController(
                text: _filterDate == null
                    ? ''
                    : DateFormat('dd/MM/yyyy').format(_filterDate!),
              ),
              decoration: InputDecoration(
                labelText: 'Fecha',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                suffixIcon: _filterDate != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: _clearDateFilter,
                      )
                    : IconButton(
                        icon: Icon(Icons.date_range, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: _pickDate,
                      ),
              ),
              onTap: _pickDate, // Abre el DatePicker al tocar el campo
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          // Campo de Tipo
          Expanded(
            child: TextField(
              controller: _typeFilterController,
              decoration: InputDecoration(
                labelText: 'Tipo',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                suffixIcon: _filterType != null && _typeFilterController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: () {
                          setState(() {
                            _typeFilterController.clear();
                            _filterType = null;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {
                  _filterType = v.isEmpty ? null : v;
                });
              },
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          // Campo de Matrícula
          Expanded(
            child: TextField(
              controller: _plateFilterController,
              decoration: InputDecoration(
                labelText: 'Matrícula',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                suffixIcon: _filterPlate != null && _plateFilterController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: () {
                          setState(() {
                            _plateFilterController.clear();
                            _filterPlate = null;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {
                  _filterPlate = v.isEmpty ? null : v;
                });
              },
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceListItem(
      BuildContext context, MantenimientoModel mantenimiento, MantenimientoProvider mantenimientoProvider) {
    final isFeatured = mantenimiento == _featuredMantenimiento;

    // Fecha prominente (vencimiento o fecha original)
    final prominentDate = mantenimiento.fechaVencimiento ?? mantenimiento.fecha;
    final prominentDateDayFmt = DateFormat('dd', 'es').format(prominentDate);
    final prominentDateMonthFmt = DateFormat('MMM', 'es').format(prominentDate);

    // Fecha original
    final originalDateDayFmt = DateFormat('dd', 'es').format(mantenimiento.fecha);
    final originalDateMonthFmt = DateFormat('MMM', 'es').format(mantenimiento.fecha);

    return Dismissible(
      key: ValueKey(mantenimiento.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error, // Fondo rojo para indicar eliminación
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError), // Icono blanco sobre el fondo rojo
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Confirmar Eliminación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text('¿Estás seguro de que quieres eliminar este mantenimiento?', style: GoogleFonts.poppins(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Eliminar', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await mantenimientoProvider.deleteMantenimiento(mantenimiento.id);
        if (mantenimientoProvider.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mantenimiento eliminado exitosamente.', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green, // SnackBar de éxito verde
            ),
          );
          if (_featuredMantenimiento?.id == mantenimiento.id) {
            // Intenta seleccionar el primero de la lista restante, o null si está vacía
            final remainingMantenimientos = mantenimientoProvider.mantenimientos;
            setState(() {
              _featuredMantenimiento = remainingMantenimientos.isNotEmpty ? remainingMantenimientos.first : null;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${mantenimientoProvider.errorMessage}',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onError), // Texto del error en color 'onError'
              ),
              backgroundColor: Theme.of(context).colorScheme.error, // Fondo del error en color 'error'
            ),
          );
          // Si hubo un error, vuelve a cargar los mantenimientos para restaurar el elemento
          mantenimientoProvider.fetchMantenimientos();
        }
      },
      child: InkWell( // Usar InkWell para un efecto de "splash" al tocar
        onTap: () {
          setState(() {
            _featuredMantenimiento = mantenimiento;
          });
        },
        child: Padding( // Añadir padding horizontal para simular el espacio de los bordes anteriores
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Ajusta este valor si necesitas más espacio
          child: IntrinsicHeight( // Para que los divisores verticales se estiren a la altura del contenido
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar los hijos para que tengan la misma altura
              children: [
                // Área de las fechas (anteriormente leading)
                SizedBox(
                  width: 80, // Ancho para el recuadro de la fecha
                  // height: 65, // No es necesario si se usa IntrinsicHeight en el padre
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Fecha Prominente (día y mes lado a lado)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            prominentDateDayFmt,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isFeatured ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 2), // Espacio entre día y mes
                          Text(
                            prominentDateMonthFmt.toLowerCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isFeatured ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      // Fecha Original (día y mes lado a lado, solo si es diferente)
                      if (mantenimiento.fechaVencimiento == null ||
                          DateFormat.yMd().format(mantenimiento.fechaVencimiento!) != DateFormat.yMd().format(mantenimiento.fecha))
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              originalDateDayFmt,
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              originalDateMonthFmt.toLowerCase(),
                              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Divisor vertical
                VerticalDivider(
                  width: 1, // Ancho del divisor vertical
                  thickness: 1,
                  color: Colors.grey.shade400, // Color del divisor
                  indent: 8, // Margen superior
                  endIndent: 8, // Margen inferior
                ),
                const SizedBox(width: 12), // Espacio entre el divisor y el contenido principal

                // Contenido principal del ListTile
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente el contenido
                    children: [
                      Text(
                        '${mantenimiento.vehiculo?.placa ?? 'N/A'} - ${mantenimiento.tipo}',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${mantenimiento.costo.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                      ),

                    ],
                  ),
                ),
                // Trailing (iconos de edición/selección)
                if (isFeatured)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary),
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => EditMaintenanceView(
                                    maintenance: mantenimiento,
                                  ),
                                ),
                              )
                              .then((_) => mantenimientoProvider.fetchMantenimientos());
                        },
                      ),
                      Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
                    ],
                  )
                else
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant), // Icono para elementos no destacados
              ],
            ),
          ),
        ),
      ),
    );
  }
}