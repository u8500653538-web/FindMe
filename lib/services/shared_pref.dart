import 'package:shared_preferences/shared_preferences.dart';

/// Helper per la gestione dei dati persistenti tramite SharedPreferences.
/// Consente di salvare, recuperare e rimuovere informazioni dell'utente
/// come ID, email, nome, città, data di nascita, ecc.

class SharedpreferenceHelper {
  // Chiavi costanti per l'accesso ai dati salvati
  static const String userIdKey = "USER_ID";
  static const String userNameKey = "USER_NAME";
  static const String userEmailKey = "USER_EMAIL";
  static const String userImageKey = "USER_IMAGE";
  static const String userCityKey = "USER_CITY";
  static const String userDOBKey = "USER_DOB";
  static const String profileCompleteKey = "PROFILE_COMPLETE";

  // -------------------- Metodi di Salvataggio --------------------

  /// Salva l'ID utente
  Future<bool> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, id);
  }

  /// Salva il nome utente
  Future<bool> saveUserDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, name);
  }

  /// Salva l'email dell'utente
  Future<bool> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, email);
  }

  /// Salva l'URL dell'immagine profilo
  Future<bool> saveUserImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImageKey, imageUrl);
  }

  /// Salva la città dell'utente
  Future<bool> saveUserCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userCityKey, city);
  }

  /// Salva la data di nascita dell'utente in formato ISO (stringa)
  Future<bool> saveUserDOB(String dob) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userDOBKey, dob);
  }

  /// Indica se il profilo è completo
  Future<bool> saveProfileComplete(bool isComplete) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(profileCompleteKey, isComplete);
  }

  // -------------------- Metodi di Lettura --------------------

  /// Recupera l'ID utente
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  /// Recupera il nome utente
  Future<String?> getUserDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  /// Recupera l'email utente
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  /// Recupera l'URL dell'immagine profilo
  Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageKey);
  }

  /// Recupera la città dell'utente
  Future<String?> getUserCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userCityKey);
  }

  /// Recupera la data di nascita
  Future<String?> getUserDOB() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userDOBKey);
  }

  /// Verifica se il profilo è completo (default: false)
  Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(profileCompleteKey) ?? false;
  }

  // -------------------- Ultima visita --------------------

  /// Salva la data/ora dell'ultima visita
  Future<void> setLastVisit(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("last_visit", dateTime.toIso8601String());
  }

  /// Recupera la data/ora dell'ultima visita (null se assente o non valida)
  Future<DateTime?> getLastVisit() async {
    final prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString("last_visit");
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  // -------------------- Pulizia dati --------------------

  /// Rimuove tutte le informazioni utente salvate
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userImageKey);
    await prefs.remove(userCityKey);
    await prefs.remove(userDOBKey);
    await prefs.remove(profileCompleteKey);
  }
}
