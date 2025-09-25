/// Classe di utilità per gestire la logica dei commenti
class CommentLogic {
  /// Costruisce la mappa del commento pronta per essere salvata su Firestore
  ///
  /// Parametri:
  /// - [username]: nome dell'utente che scrive il commento
  /// - [userimage]: URL dell'immagine del profilo dell'utente
  /// - [text]: testo del commento
  ///
  /// Restituisce una [Map] con i campi necessari per Firestore.

  static Map<String, dynamic> buildComment({
    required String username,
    required String userimage,
    required String text,
  }) {
    return {
      "UserImage": userimage,
      "UserName": username,
      "Comment": text.trim(), // Rimuove eventuali spazi all'inizio/fine
    };
  }
}
