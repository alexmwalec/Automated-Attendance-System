import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential results =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = results.user;

      if (user == null) return null;

      String uid = user.uid;

      DocumentSnapshot doc =
      await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception("User document not found in Firestore");
      }

      return doc.get('role');
    } on FirebaseAuthException catch (e) {
      throw Exception("Auth error: ${e.code}");
    } on FirebaseException catch (e) {
      throw Exception("Firestore error: ${e.code}");
    } catch (e) {
      throw Exception("Unknown error: $e");
    }
  }
}