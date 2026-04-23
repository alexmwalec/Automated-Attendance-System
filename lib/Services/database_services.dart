import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> signIn(String email, String password) async {
    UserCredential results = await _auth.signInWithEmailAndPassword(email: email, password: password);

    User? user = results.user;
    if (user != null) {
      String uid = user.uid;
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.get('role');
    }
    return null;
    }
  }
