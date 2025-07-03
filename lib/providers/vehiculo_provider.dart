// lib/providers/vehiculo_provider.dart
import 'package:flutter/material.dart';
import 'package:yana/models/vehiculo_model.dart';
import 'package:yana/repository/vehiculo_repository.dart';

class VehiculoProvider extends ChangeNotifier {
  VehiculoRepository _repo;
  List<VehiculoModel> _vehiculos = [];
  String? _errorMessage;
  bool _isLoading = false;

  VehiculoProvider(this._repo);

  List<VehiculoModel> get vehiculos => _vehiculos;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  // ¡NUEVO MÉTODO! Para actualizar el repositorio cuando el token cambia
  void updateRepository(VehiculoRepository newRepo) {
    if (_repo != newRepo) { // Evita notificaciones innecesarias si el repo es el mismo
      _repo = newRepo;
      // Opcional: podrías querer volver a cargar los vehículos si el repo cambió
      // Esto es útil si el cambio de repositorio implica un cambio en los datos
      // (ej. el token cambió y ahora podemos obtener datos que antes no podíamos).
      // Solo si estás seguro de que _repo.fetchVehiculos() es seguro de llamar
      // en este punto (es decir, AuthProvider ya está autenticado).
      // Por lo general, esto se gatillaría desde la UI o después de un successful login.
      // fetchVehiculos();
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Método para limpiar la lista de vehículos (ej. al desloguearse)
  void clearVehiculos() {
    _vehiculos = [];
    _errorMessage = null;
    _isLoading = false; // Asegurarse de que el estado de carga también se resetee
    notifyListeners(); // Notifica a los listeners que la lista se ha limpiado
  }

  Future<void> fetchVehiculos() async {
    if (_isLoading) return; // Evita llamadas múltiples si ya está cargando

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _vehiculos = await _repo.fetchVehiculos();
    } catch (e) {
      _errorMessage = e.toString();
      _vehiculos = []; // Limpiar si hay error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createVehiculo(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final newVehiculo = await _repo.createVehiculo(data);
      _vehiculos.add(newVehiculo);
      // Opcional: Si el backend puede devolver el vehículo con un ID,
      // añadirlo directamente es eficiente. Si el orden importa o hay
      // lógica de paginación/filtrado, `fetchVehiculos()` podría ser mejor.
      // await fetchVehiculos(); // Considera si realmente necesitas esto para cada creación
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para actualizar y eliminar vehículos
  Future<void> updateVehiculo(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedVehiculo = await _repo.updateVehiculo(id, data);
      // Encuentra y reemplaza el vehículo actualizado en la lista
      int index = _vehiculos.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehiculos[index] = updatedVehiculo;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVehiculo(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.deleteVehiculo(id);
      _vehiculos.removeWhere((v) => v.id == id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}