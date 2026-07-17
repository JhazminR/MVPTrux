import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia a la colección de vehículos
  CollectionReference get _vehiclesCollection => _firestore.collection('vehicles');

  // Enviar ubicación del conductor
  Future<void> updateDriverLocation(String driverId, Position position) async {
    await _vehiclesCollection.doc(driverId).set({
      'latitud': position.latitude,
      'longitud': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'activo': true,
      // Podrías agregar más datos: ruta, estado, etc.
    });
  }

  // Escuchar cambios en todos los vehículos (para pasajeros)
  Stream<QuerySnapshot> getVehiclesStream() {
    return _vehiclesCollection.where('activo', isEqualTo: true).snapshots();
  }
}