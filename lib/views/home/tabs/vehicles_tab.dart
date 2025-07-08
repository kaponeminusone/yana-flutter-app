// lib/views/home/tabs/vehicles_tab.dart
import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart'; // Mantener si todavía usas el visor 3D
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart'; // ¡Eliminado! Google Fonts se maneja en el tema global
import 'package:flutter_localizations/flutter_localizations.dart'; // Necesario para Localizations.override

import 'package:yana/models/vehiculo_model.dart';
import 'package:yana/providers/vehiculo_provider.dart';
import 'package:yana/utils/vehicle_model_viewer.dart'; // Mantener
import 'package:yana/views/documents/docs_view.dart';
import 'package:yana/views/vehicles/edit_vehicle_view.dart';
import 'package:yana/models/obligacion_legal_model.dart';
import 'package:yana/providers/obligacion_legal_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().fetchVehiculos().then((_) {
        // Una vez que los vehículos se cargan, establece el primero como destacado
        // y carga sus obligaciones.
        if (context.read<VehiculoProvider>().vehiculos.isNotEmpty) {
          _updateFeaturedVehiculo(context.read<VehiculoProvider>().vehiculos[0]);
        }
      });
    });
  }

  // Función para actualizar el vehículo destacado y obtener sus obligaciones
  Future<void> _updateFeaturedVehiculo(VehiculoModel vehiculo) async {
    setState(() {
      _featuredVehicle = vehiculo;
    });
    // Obtener obligaciones para el vehículo seleccionado
    final obligacionProvider = Provider.of<ObligacionLegalProvider>(context, listen: false);
    await obligacionProvider.fetchObligacionesByVehiculoId(vehiculo.id);
  }

  @override
  Widget build(BuildContext context) {
    final vehProv = context.watch<VehiculoProvider>();
    final obligacionProv = context.watch<ObligacionLegalProvider>(); // Observar ObligacionLegalProvider
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;


    if (vehProv.isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary)); // Usa primaryColor del tema
    }

    if (vehProv.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, color: colorScheme.onSurfaceVariant, size: 80), // Ícono de error
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
              if (vehProv.errorMessage != null && vehProv.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Detalles: ${vehProv.errorMessage}', // Mostrar detalles técnicos para depuración
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon( // Usar ElevatedButton.icon para un botón más visual
                onPressed: () {
                  vehProv.clearErrorMessage();
                  vehProv.fetchVehiculos();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // Usa primaryColor del tema
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh), // Ícono de refrescar
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 80, color: colorScheme.outlineVariant),
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
    if (_featuredVehicle == null && vehicles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFeaturedVehiculo(vehicles[0]);
      });
      return Center(child: CircularProgressIndicator(color: colorScheme.primary)); // Usa primaryColor del tema
    }

    // Si _featuredVehicle no es nulo, obtenemos sus obligaciones cargadas por el provider
    final List<ObligacionLegalModel> featuredVehicleObligations = obligacionProv.obligaciones;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            color: Colors.transparent, // Fondo transparente como antes
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
            minHeight: 180,
            maxHeight: 180,
            child: _DocsInfoSection(
              vehicle: _featuredVehicle!, // Pasa el vehículo destacado real
              obligaciones: featuredVehicleObligations, // Pasa las obligaciones reales
              areDocsLoading: obligacionProv.isLoading,
              docsErrorMessage: obligacionProv.errorMessage,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = vehicles[index];
                final isSelected = v.id == _featuredVehicle?.id;
                final icon = v.modelo.toLowerCase().contains('moto')
                    ? Icons.two_wheeler
                    : Icons.directions_car;

                return Column(
                  children: [
                    Dismissible(
                      key: ValueKey(v.id), // Clave única para el Dismissible
                      direction: DismissDirection.endToStart, // Solo de derecha a izquierda
                      background: Container(
                        color: colorScheme.error, // Usa el color de error del tema
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: colorScheme.onError, size: 36),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Localizations.override( // Para asegurar que las fechas se formateen correctamente
                              context: context,
                              locale: const Locale('es', 'ES'), // O la configuración regional que desees
                              child: Builder(
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'Confirmar eliminación',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      '¿Estás seguro de que quieres eliminar este vehículo?',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false), // No eliminar
                                        child: Text(
                                          'Cancelar',
                                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true), // Eliminar
                                        child: Text(
                                          'Eliminar',
                                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              ),
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        // Eliminar el vehículo después de la confirmación
                        await vehProv.deleteVehiculo(v.id);
                        if (_featuredVehicle?.id == v.id) {
                          // Si el vehículo eliminado era el destacado, intenta seleccionar el primero de la lista restante
                          // o establece a null si no quedan vehículos.
                          if (vehProv.vehiculos.isNotEmpty) {
                            _updateFeaturedVehiculo(vehProv.vehiculos[0]);
                          } else {
                            setState(() {
                              _featuredVehicle = null;
                            });
                          }
                        }
                        // Opcional: mostrar un SnackBar de confirmación
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Vehículo ${v.marca} ${v.modelo} eliminado',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () => _updateFeaturedVehiculo(v),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 24),
                              SizedBox(
                                height: 40, // Altura del divisor vertical
                                child: VerticalDivider(thickness: 1, color: colorScheme.outlineVariant),
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
                                Icon(Icons.check_circle, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.edit, color: colorScheme.primary),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EditVehicleView(vehicle: v),
                                      ),
                                    ).then((result) {
                                      if (result == true) {
                                        vehProv.fetchVehiculos();
                                        if (_featuredVehicle != null) {
                                          _updateFeaturedVehiculo(_featuredVehicle!);
                                        }
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
                    Divider(height: 1, color: colorScheme.outlineVariant), // Divisor entre ítems
                  ],
                );
              },
              childCount: vehicles.length,
            ),
          ),
        ),
      ],
    );
  }
}

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
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _DocsHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

// _DocsInfoSection (Anteriormente _DocsCard - REDISEÑADO)
class _DocsInfoSection extends StatelessWidget {
  final VehiculoModel vehicle;
  final List<ObligacionLegalModel> obligaciones; // Ahora recibe ObligacionLegalModel
  final bool areDocsLoading;
  final String? docsErrorMessage;

  const _DocsInfoSection({
    Key? key,
    required this.vehicle,
    required this.obligaciones,
    this.areDocsLoading = false,
    this.docsErrorMessage,
  }) : super(key: key);

  // Función de ayuda para determinar el color del estado
  Color _getDocumentStatusColor(String obligationName) {
    final obligacion = obligaciones.firstWhereOrNull(
      (o) => o.nombre.toLowerCase().contains(obligationName.toLowerCase()),
    );

    if (obligacion == null) {
      return Colors.grey; // No encontrado
    }
    // Considerar que `archivoPath` podría ser una URL o un path local.
    // La lógica de `null` vs `isEmpty` depende de cómo manejas los paths.
    // Asumiré que `null` o una cadena vacía significa que falta el archivo.
    if (obligacion.archivoPath == null || obligacion.archivoPath!.isEmpty) {
      return Colors.orange; // Falta el archivo
    }
    if (obligacion.fechaVencimiento == null) {
      return Colors.yellow; // Sin fecha de vencimiento (puede indicar que es permanente o indefinido)
    }
    if (obligacion.fechaVencimiento!.isBefore(DateTime.now())) {
      return Colors.red; // Vencido
    }
    return Colors.green; // Vigente
  }

  // Función de ayuda para obtener la fecha de vencimiento formateada
  String? _getFormattedDueDate(String obligationName) {
    final obligacion = obligaciones.firstWhereOrNull(
      (o) => o.nombre.toLowerCase().contains(obligationName.toLowerCase()),
    );
    return obligacion?.formattedFechaVencimiento;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final String placa = vehicle.placa ?? 'N/A';
    final String marca = vehicle.marca ?? 'Marca Desconocida';
    final String modelo = vehicle.modelo ?? 'Modelo Desconocida';
    final int year = vehicle.year ?? 0;
    final String color = vehicle.color ?? 'Color Desconocido';

    final List<String> documentTypesToShow = [
      'SOAT',
      'Técnico-Mecánica', // O 'Tecno', 'TecnoMecanica'
      'Propiedad', // O 'Tarjeta de Propiedad'
      'Seguro', // O 'SeguroContractual'
      'Licencia' // O 'Licencia de Transito'
    ];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Usa el color de fondo del Scaffold
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
                icon: Icon(Icons.arrow_forward_ios, color: colorScheme.primary), // Usa primaryColor
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocsView(
                        vehiculo: vehicle,
                        obligaciones: obligaciones,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      Provider.of<ObligacionLegalProvider>(context, listen: false)
                          .fetchObligacionesByVehiculoId(vehicle.id);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outlineVariant), // Divisor
          const SizedBox(height: 8),
          Text(
            'Documentos y Obligaciones',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          if (areDocsLoading)
            Center(child: CircularProgressIndicator(color: colorScheme.primary)) // Usa primaryColor
          else if (docsErrorMessage != null)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: Text(
                    'Error al cargar documentos: $docsErrorMessage',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  ),
                ),
              ),
            )
          else if (obligaciones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No hay documentos legales registrados para este vehículo.',
                  style: textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: documentTypesToShow.length,
                itemBuilder: (_, i) {
                  final docType = documentTypesToShow[i];
                  final dotColor = _getDocumentStatusColor(docType);
                  final dueDate = _getFormattedDueDate(docType);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _DocTile(
                      name: docType,
                      dotColor: dotColor,
                      dueDate: dueDate,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Documento Tile (se mantienen los estilos originales y se aplica el textTheme)
class _DocTile extends StatelessWidget {
  final String name;
  final Color dotColor;
  final String? dueDate;
  const _DocTile({Key? key, required this.name, required this.dotColor, this.dueDate})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.description, size: 32, color: colorScheme.primary), // Icono azul del tema
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
                      width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(name, style: textTheme.bodySmall), // Usa bodySmall del tema
        if (dueDate != null)
          Text(dueDate!,
              style: textTheme.bodySmall?.copyWith(
                  color: dotColor == Colors.red ? colorScheme.error : textTheme.bodySmall?.color)), // Usa error del tema
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