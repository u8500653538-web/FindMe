import 'package:cloud_firestore/cloud_firestore.dart';

/// Classe di utilità per le operazioni CRUD su Firestore.
/// Gestisce utenti, post, like, commenti, ricerche e token di notifica.
class DatabaseMethods {
  // -------------------- Utenti --------------------

  /// Aggiunge o aggiorna i dettagli dell'utente
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  /// Ottiene un utente tramite email
  Future<QuerySnapshot> getUserbyEmail(String email) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("Email", isEqualTo: email)
        .get();
  }

  /// Ottiene un utente tramite ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();
  }

  /// Aggiorna il token FCM dell’utente
  Future<void> updateUserToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update({"fcmToken": token});
  }

  // -------------------- Post --------------------

  /// Aggiunge un nuovo post con [id] specifico
  Future addPost(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Posts")
        .doc(id)
        .set(userInfoMap);
  }

  /// Ottiene tutti i post in ordine di creazione (ascendente)
  Stream<QuerySnapshot> getPosts() {
    return FirebaseFirestore.instance
        .collection("Posts")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }

  /// Ottiene tutti i post (qui il parametro city non è utilizzato)
  Stream<QuerySnapshot> getPostsPlace(String city) {
    return FirebaseFirestore.instance
        .collection("Posts")
        .orderBy("createdAt", descending: false)
        .snapshots();
  }

  // -------------------- Like --------------------

  /// Aggiunge un like al post con ID [id] per l’utente [userid]
  Future addLike(String id, String userid) async {
    return await FirebaseFirestore.instance
        .collection("Posts")
        .doc(id)
        .update({
      'Like': FieldValue.arrayUnion([userid])
    });
  }

  /// Alterna il like: se l’utente ha già messo “mi piace”, lo rimuove; altrimenti lo aggiunge
  Future toggleLike(String postId, String userId) async {
    DocumentReference postRef =
    FirebaseFirestore.instance.collection("Posts").doc(postId);

    DocumentSnapshot snapshot = await postRef.get();

    if (snapshot.exists) {
      // Recupera lista di like esistenti (lista vuota se null)
      List likes = snapshot["Like"] ?? [];

      if (likes.contains(userId)) {
        // Rimuove il like
        await postRef.update({
          "Like": FieldValue.arrayRemove([userId])
        });
      } else {
        // Aggiunge il like
        await postRef.update({
          "Like": FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  // -------------------- Commenti --------------------

  /// Aggiunge un commento al post con ID [id]
  Future addComment(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("Posts")
        .doc(id)
        .collection("Comment")
        .add(userInfoMap);
  }

  /// Ottiene i commenti di un determinato post come Stream
  Stream<QuerySnapshot> getComments(String id) {
    return FirebaseFirestore.instance
        .collection("Posts")
        .doc(id)
        .collection("Comment")
        .snapshots();
  }

  // -------------------- Ricerca --------------------

  /// Ricerca nella collezione "Location" filtrando con la prima lettera maiuscola
  Future<QuerySnapshot> search(String updatedname) async {
    return await FirebaseFirestore.instance
        .collection("Location")
        .where(
      "SearchKey",
      isEqualTo: updatedname.substring(0, 1).toUpperCase(),
    )
        .get();
  }
}
