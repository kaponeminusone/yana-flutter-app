import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:o3d/o3d.dart';
import 'package:provider/provider.dart';

import 'package:yana/models/vehiculo_model.dart';
import 'package:yana/providers/vehiculo_provider.dart';
import 'package:yana/utils/vehicle_model_viewer.dart';
import 'package:yana/views/documents/docs_view.dart';
import 'package:yana/views/vehicles/edit_vehicle_view.dart';
import 'package:yana/models/obligacion_legal_model.dart';
import 'package:yana/providers/obligacion_legal_provider.dart';
// Importaciones existentes
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener esta importación para DateFormat


class VehiclesTab extends StatefulWidget {
  const VehiclesTab({Key? key}) : super(key: key);

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  VehiculoModel? _featuredVehicle; // Variable para el vehículo destacado

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Usar `read` para la carga inicial y no escuchar cambios
      await context.read<VehiculoProvider>().fetchVehiculos();

      // Asegurarse de que el widget aún esté montado después del `await`
      if (!mounted) return;

      final vehiculos = context.read<VehiculoProvider>().vehiculos;
      if (vehiculos.isNotEmpty) {
        _updateFeaturedVehiculo(vehiculos[0]);
      } else {
        // [MODIFICACIÓN 1]: Si no hay vehículos, asegúrate de que las obligaciones también estén vacías
        context.read<ObligacionLegalProvider>().clearObligaciones();
      }
    });
  }

  // Función para actualizar el vehículo destacado y obtener sus obligaciones
  Future<void> _updateFeaturedVehiculo(VehiculoModel vehiculo) async {
    // Solo actualiza si el widget está montado
    if (!mounted) return;

    setState(() {
      _featuredVehicle = vehiculo;
    });
    // Obtener obligaciones para el vehículo seleccionado
    final obligacionProvider = Provider.of<ObligacionLegalProvider>(
      context,
      listen: false,
    );
    // Esta llamada ahora le dice al provider que filtre por este vehiculo.id
    await obligacionProvider.fetchObligacionesByVehiculoId(vehiculo.id);
  }

  @override
  Widget build(BuildContext context) {
    final vehProv = context.watch<VehiculoProvider>();
    final obligacionProv = context
        .watch<ObligacionLegalProvider>(); // Observar ObligacionLegalProvider
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (vehProv.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (vehProv.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                color: colorScheme.onSurfaceVariant,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Parece que hay un problema de conexión o el servidor no responde.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor, verifica tu conexión a internet o intenta de nuevo más tarde.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
              ),
              if (vehProv.errorMessage != null &&
                  vehProv.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Detalles: ${vehProv.errorMessage}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  vehProv.clearErrorMessage();
                  await vehProv.fetchVehiculos();

                  if (!mounted) return;

                  final vehiculos = vehProv.vehiculos;
                  if (vehiculos.isNotEmpty) {
                    _updateFeaturedVehiculo(vehiculos[0]);
                  } else {
                    // [MODIFICACIÓN 2]: Si después del reintento no hay vehículos, limpia las obligaciones
                    context.read<ObligacionLegalProvider>().clearObligaciones();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Reintentar Carga',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final vehicles = vehProv.vehiculos;
    if (vehicles.isEmpty) {
      // [MODIFICACIÓN 3]: Si no hay vehículos, también asegúrate de limpiar las obligaciones
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ObligacionLegalProvider>().clearObligaciones();
        }
      });
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes vehículos registrados.',
              style: textTheme.titleLarge?.copyWith(
                color: textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón "+" en la pantalla principal para agregar uno.',
              style: textTheme.bodyMedium?.copyWith(
                color: textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Asegurarse de que _featuredVehicle esté inicializado al menos con el primer vehículo
    // Esto se maneja en initState, pero como fallback o si el estado se reconstruye
    // antes de que initState complete el fetch.
    if (_featuredVehicle == null && vehicles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateFeaturedVehiculo(vehicles[0]);
        }
      });
      // Mientras esperamos la actualización, podemos mostrar un indicador
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    // Si _featuredVehicle no es nulo, obtenemos sus obligaciones cargadas por el provider.
    // Esta lista ya está filtrada por el ObligacionLegalProvider.
    final List<ObligacionLegalModel> featuredVehicleObligations =
        obligacionProv.obligaciones;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            color: Colors.transparent,
            child: VehicleModelViewer(
              assetPath: 'assets/3dmodels/nissan.glb',
              autoRotate: false,
              autoPlay: false,
              initialCameraOrbit: CameraOrbit(262, 87.88, 1.5),
              initialCameraTarget: CameraTarget(-0.05, 1.54, -0.3),
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _DocsHeaderDelegate(
            minHeight: 206,
            maxHeight: 206,
            child: _DocsInfoSection(
              vehicle: _featuredVehicle!, // Pasa el vehículo destacado real
              obligaciones:
                  featuredVehicleObligations, // Pasa las obligaciones REALES y ya FILTRADAS
              areDocsLoading: obligacionProv.isLoading,
              docsErrorMessage: obligacionProv.errorMessage,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final v = vehicles[index];
              final isSelected = v.id == _featuredVehicle?.id;
              final icon = v.modelo.toLowerCase().contains('moto')
                  ? Icons.two_wheeler
                  : Icons.directions_car;

              return Column(
                children: [
                  Dismissible(
                    key: ValueKey(v.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        Icons.delete,
                        color: colorScheme.onError,
                        size: 36,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      bool confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: Text(
                                  'Confirmar eliminación',
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  '¿Estás seguro de que quieres eliminar este vehículo?',
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        color: Theme.of(dialogContext)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        color: Theme.of(dialogContext)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;

                      if (confirmDelete == true) {
                        final bool success = await vehProv.deleteVehiculo(v.placa);

                        if (!mounted) {
                          return false;
                        }

                        if (success) {
                          if (_featuredVehicle?.id == v.id) {
                            if (vehProv.vehiculos.isNotEmpty) {
                              _updateFeaturedVehiculo(vehProv.vehiculos[0]);
                            } else {
                              // [MODIFICACIÓN 4]: Si se elimina el último vehículo, limpia _featuredVehicle y las obligaciones
                              setState(() {
                                _featuredVehicle = null;
                              });
                              context.read<ObligacionLegalProvider>().clearObligaciones();
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Vehículo ${v.marca} ${v.modelo} eliminado exitosamente.',
                                style: textTheme.bodyMedium,
                              ),
                              backgroundColor: colorScheme.secondary,
                            ),
                          );
                          return true;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al eliminar vehículo: ${vehProv.errorMessage ?? 'Error desconocido'}',
                                style: textTheme.bodyMedium
                                    ?.copyWith(color: colorScheme.onError),
                              ),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                          return false;
                        }
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      // Ya manejado en confirmDismiss
                    },
                    child: InkWell(
                      onTap: () {
                        if (!mounted) return;
                        _updateFeaturedVehiculo(v);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              height: 40,
                              child: VerticalDivider(
                                thickness: 1,
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${v.marca} ${v.modelo}',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Placa: ${v.placa}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  Text(
                                    'Año: ${v.year}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditVehicleView(vehicle: v),
                                        ),
                                      )
                                      .then((result) {
                                        if (!mounted) return;

                                        if (result == true) {
                                          context
                                              .read<VehiculoProvider>()
                                              .fetchVehiculos();
                                          final updatedVehicles = context
                                              .read<VehiculoProvider>()
                                              .vehiculos;
                                          final updatedFeaturedVehicle =
                                              updatedVehicles.firstWhere(
                                            (element) => element.id == v.id,
                                            orElse: () => v,
                                          );
                                          _updateFeaturedVehiculo(
                                              updatedFeaturedVehicle);
                                        }
                                      });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                ],
              );
            }, childCount: vehicles.length),
          ),
        ),
      ],
    );
  }
}
// Clase _DocsInfoSection (ya la tienes y es correcta)
// Clase _DocTile (ya la tienes y es correcta)
// Extension ListExtension (ya la tienes y es correcta)

// Delegate para SliverPersistentHeader (sin cambios funcionales, solo se renombró el child)
class _DocsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _DocsHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _DocsHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}
class _DocsInfoSection extends StatelessWidget {
  final VehiculoModel vehicle;
  final List<ObligacionLegalModel> obligaciones; // Now receives ObligacionLegalModel
  final bool areDocsLoading;
  final String? docsErrorMessage;

  const _DocsInfoSection({
    Key? key,
    required this.vehicle,
    required this.obligaciones,
    this.areDocsLoading = false,
    this.docsErrorMessage,
  }) : super(key: key);

  // No longer need _getDocumentStatusColor or _getFormattedDueDate as helper
  // functions here because _DocTile will receive the actual ObligacionLegalModel
  // and determine its own status/date. We can make _DocTile take ObligacionLegalModel
  // directly, or keep these helper functions but call them differently.
  // For simplicity and directness, let's adjust _DocTile to take ObligacionLegalModel.

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final String placa = vehicle.placa ?? 'N/A';
    final String marca = vehicle.marca ?? 'Marca Desconocida';
    final String modelo = vehicle.modelo ?? 'Modelo Desconocida';
    final int year = vehicle.year ?? 0;
    final String color = vehicle.color ?? 'Color Desconocido';

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$marca $modelo ($year)',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placa: $placa',
                      style: textTheme.bodyMedium?.copyWith(
                        color: textTheme.bodyMedium?.color,
                      ),
                    ),
                    Text(
                      'Color: $color',
                      style: textTheme.bodyMedium?.copyWith(
                        color: textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => DocsView(
                            vehiculo: vehicle,
                            obligaciones: obligaciones,
                          ),
                        ),
                      )
                      .then((result) {
                        if (result == true) {
                          Provider.of<ObligacionLegalProvider>(
                            context,
                            listen: false,
                          ).fetchObligacionesByVehiculoId(vehicle.id);
                        }
                      });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Text(
            'Documentos y Obligaciones',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: () {
              if (areDocsLoading) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }
              if (docsErrorMessage != null) {
                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error al cargar documentos: $docsErrorMessage\nPulsa "Reintentar" en la vista de documentos para ver los datos de ejemplo.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                );
              }
              // IMPORTANT CHANGE HERE:
              if (obligaciones.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    child: Text(
                      'No hay documentos legales registrados para este vehículo.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                );
              }
              // Iterate directly over the fetched obligations list
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: obligaciones.length, // Use the actual number of fetched obligations
                itemBuilder: (_, i) {
                  final obligacion = obligaciones[i];
                  // Pass the entire ObligacionLegalModel to _DocTile
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 80, // Adjust width as needed
                      child: _DocTile(
                        obligacion: obligacion, // Pass the full model
                      ),
                    ),
                  );
                },
              );
            }(),
          ),
        ],
      ),
    );
  }
}

// Documento Tile - MODIFIED to receive ObligacionLegalModel
class _DocTile extends StatelessWidget {
  final ObligacionLegalModel obligacion; // Changed to receive the full model

  const _DocTile({
    Key? key,
    required this.obligacion,
  }) : super(key: key);

  // Helper to determine status color based on the received obligation
  Color _getDotColor() {
    if (obligacion.documentoPath == null || obligacion.documentoPath!.isEmpty) {
      return Colors.orange; // Falta el archivo
    }
    if (obligacion.fechaVencimiento == null) {
      return Colors.yellow; // Sin fecha de vencimiento (e.g., permanente)
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(
      obligacion.fechaVencimiento!.year,
      obligacion.fechaVencimiento!.month,
      obligacion.fechaVencimiento!.day,
    );
    if (exp.isBefore(today)) return Colors.red; // Vencido
    if (exp.difference(today).inDays <= 30) return Colors.orange; // Próximo a vencer
    return Colors.green; // Vigente
  }

  // Helper to get formatted date based on the received obligation
  String? _getFormattedDueDate() {
    if (obligacion.fechaVencimiento == null) return null;
    return DateFormat('dd MMM', 'es').format(obligacion.fechaVencimiento!); // Simplified format for small tile
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final dotColor = _getDotColor();
    final dueDate = _getFormattedDueDate();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.description,
              size: 32,
              color: colorScheme.primary,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          obligacion.nombre ?? 'N/A', // Use the actual obligation name
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (dueDate != null)
          Text(
            dueDate!,
            style: textTheme.bodySmall?.copyWith(
              color: dotColor == Colors.red
                  ? colorScheme.error
                  : textTheme.bodySmall?.color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

// Extensión para List para firstWhereOrNull, si aún no la tienes
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}