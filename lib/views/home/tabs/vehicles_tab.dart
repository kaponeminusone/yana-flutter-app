// lib/views/home/tabs/vehicles_tab.dart
import 'package:flutter/material.dart';
import 'package:yana/views/documents/docs_view.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({Key? key}) : super(key: key);

  @override
  State<VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  int selectedIndex = 0;

  // Datos de ejemplo
  final vehicles = List.generate(
    20,
    (i) => {
      'brand': 'Vehículo #${i + 1}',
      'plate': 'XYZ-${200 + i}', // Agregamos una placa para el ejemplo
      'isCar': i % 2 == 0, // Indicador de si es carro o moto
      'docs': [
        {'name': 'SOAT', 'status': Colors.green},
        {'name': 'Propiedad', 'status': Colors.yellow},
        {'name': 'Revisión1', 'status': Colors.red},
        {'name': 'Revisión2', 'status': Colors.red},
        {'name': 'Revisión3', 'status': Colors.red},
        {'name': 'Revisión4', 'status': Colors.red},
        {'name': 'Revisión5', 'status': Colors.red},
        {'name': 'Revisión6', 'status': Colors.red},
      ],
    },
  );

  @override
  Widget build(BuildContext context) {
    final featured = vehicles[selectedIndex];

    return CustomScrollView(
      slivers: [
        // Modelo 3D que desaparece al scrollear
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            color: Colors.black12,
            child: const Center(
              child: Text(
                '📦 Modelo 3D',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
          ),
        ),

        // Header persistente con card redondeada abajo
        SliverPersistentHeader(
          pinned: true,
          delegate: _DocsHeaderDelegate(
            minHeight: 141,
            maxHeight: 141,
            child: _DocsCard(data: featured),
          ),
        ),

        // Lista de vehículos con el nuevo diseño
        SliverPadding( // Agregamos un padding al SliverList para que no se pegue a los bordes
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final v = vehicles[index];
                final isSelected = index == selectedIndex;
                final icon = v['isCar'] == true ? Icons.directions_car : Icons.two_wheeler; // Ícono dinámico
                
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            // Ícono de vehículo (carro o moto)
                            Icon(icon, size: 32, color: Colors.black54),
                            
                            const SizedBox(width: 24), // Espacio entre el ícono y el divisor
                            
                            // Divisor vertical
                            const SizedBox(
                              height: 40, // Altura fija para el divisor
                              child: VerticalDivider(
                                thickness: 1,
                                color: Colors.grey,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Información del vehículo
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v['brand'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Placa: ${v['plate']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Indicador de selección
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check_circle, color: Colors.blue),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1), // Divisor horizontal entre elementos de la lista
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

// Delegate para SliverPersistentHeader
class _DocsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _DocsHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _DocsHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

// Widget para cada documento
class _DocTile extends StatelessWidget {
  final String name;
  final Color dotColor;
  const _DocTile({Key? key, required this.name, required this.dotColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.description, size: 32),
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
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ... (resto del código de VehiclesTab)

// Card de documentos y marca con bordes inferiores redondeados
class _DocsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DocsCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docs = data['docs'] as List;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Material(
        elevation: 0,
        color: Colors.red.shade50,
        child: Padding(
          // Reduje el padding vertical para tener más espacio
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Esto es importante. Usa el espacio que necesita.
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título con la marca y el botón de flecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Usa Expanded para que el texto no genere overflow
                  Expanded(
                    child: Text(
                      data['brand'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis, // Evita overflow si el texto es muy largo
                    ),
                  ),
                  // El nuevo botón de flecha
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    iconSize: 20,
                    color: Colors.black54,
                    onPressed: () {
                      // Navega a la nueva vista de documentos
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DocsView(vehicleData: data),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ListView horizontal para los documentos
              SizedBox(
                height: 65, // Aumenté ligeramente la altura para evitar overflows
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _DocTile(
                        name: doc['name'] as String,
                        dotColor: doc['status'] as Color,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}