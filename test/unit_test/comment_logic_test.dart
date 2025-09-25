import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'package:findme_programmazione_mobile/models/comment_logic.dart';

// Genera il mock della classe DatabaseMethods
@GenerateMocks([DatabaseMethods])
import 'comment_logic_test.mocks.dart';

void main() {
  group('CommentLogic + DatabaseMethods', () {
    late MockDatabaseMethods mockDb;

    setUp(() {
      // Inizializza il mock prima di ogni test
      mockDb = MockDatabaseMethods();
    });

    test('buildComment crea la mappa corretta', () {
      // Testa che la funzione buildComment generi correttamente la mappa del commento
      final result = CommentLogic.buildComment(
        username: 'Mario',
        userimage: 'image_url',
        text: ' Ciao mondo  ', // spazi extra che devono essere rimossi
      );

      // Verifica i valori della mappa
      expect(result['UserName'], 'Mario');
      expect(result['UserImage'], 'image_url');
      expect(result['Comment'], 'Ciao mondo'); // conferma il trim
    });

    test('aggiunge commento al database', () async {
      // Dati di esempio per il commento
      final username = 'Mario';
      final userimage = 'image_url';
      final text = 'Ciao mondo';
      final postid = 'post123';

      // Costruzione del commento usando CommentLogic
      final comment = CommentLogic.buildComment(
        username: username,
        userimage: userimage,
        text: text,
      );

      // Configura il mock per restituire Future<void> quando addComment viene chiamato
      when(mockDb.addComment(comment, postid)).thenAnswer((_) async {});

      // Chiama la funzione addComment sul mock
      await mockDb.addComment(comment, postid);

      // Verifica che il metodo addComment sia stato chiamato una sola volta
      verify(mockDb.addComment(comment, postid)).called(1);
    });
  });
}
