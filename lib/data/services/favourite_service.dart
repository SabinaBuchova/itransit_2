import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/favourite_stop.dart';

class FavouritesService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static CollectionReference? get _collection {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('favourites');
  }

  // Načítaj obľúbené
  static Stream<List<FavouriteStop>> favouritesStream() {
    if (_collection == null) return Stream.value([]);

    return _collection!.snapshots().map((snap) => snap.docs
        .map((doc) => FavouriteStop.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  // Pridaj obľúbenú
  static Future<void> add(FavouriteStop stop) async {
    if (_collection == null) return;
    await _collection!.doc(stop.stopId).set(stop.toMap());
  }

  // Odober obľúbenú
  static Future<void> remove(String stopId) async {
    if (_collection == null) return;
    await _collection!.doc(stopId).delete();
  }

  // Je zastávka obľúbená?
  static Future<bool> isFavourite(String stopId) async {
    if (_collection == null) return false;
    final doc = await _collection!.doc(stopId).get();
    return doc.exists;
  }
}