import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/evento.dart';

class FirebaseService {
  FirebaseService._();
  static final instance = FirebaseService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ======= AUTH =======
  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<User?> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() async => _auth.signOut();

  User? get currentUser => _auth.currentUser;

  // ======= FIRESTORE (colección por usuario) =======
  CollectionReference<Map<String, dynamic>> _colEventos(String uid) =>
      _db.collection('users').doc(uid).collection('eventos');

  Stream<List<Evento>> streamEventos() {
    final uid = currentUser?.uid;
    if (uid == null) {
      // Si no hay usuario, stream vacío
      return const Stream<List<Evento>>.empty();
    }
    return _colEventos(uid)
        .orderBy('fechaMillis', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final ts = data['fecha'] as Timestamp?;
              return Evento(
                id: d.id,
                nombre: (data['nombre'] ?? '') as String,
                fecha: ts?.toDate(),
                reservado: (data['reservado'] ?? false) as bool,
                notas: data['notas'] as String?,
              );
            }).toList());
  }

  Future<void> addEvento(Evento e) async {
    final uid = currentUser!.uid;
    await _colEventos(uid).add({
      'nombre': e.nombre,
      'fecha': e.fecha == null ? null : Timestamp.fromDate(e.fecha!),
      'fechaMillis': e.fecha?.millisecondsSinceEpoch ?? 0,
      'reservado': e.reservado,
      'notas': e.notas,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleReservado(Evento e) async {
    final uid = currentUser!.uid;
    await _colEventos(uid).doc(e.id).update({'reservado': !e.reservado});
  }

  Future<void> deleteEvento(Evento e) async {
    final uid = currentUser!.uid;
    await _colEventos(uid).doc(e.id).delete();
  }
}