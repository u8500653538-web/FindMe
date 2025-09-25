import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:findme_programmazione_mobile/pages/comment.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mock manuale per DatabaseMethods
class MockDatabase extends DatabaseMethods {
  bool addCommentCalled = false; // Flag per verificare se addComment è stato chiamato

  @override
  Stream<QuerySnapshot> getComments(String postId) {
    // Restituisce uno Stream finto di QuerySnapshot
    return Stream.value(FakeQuerySnapshot([]));
  }

  @override
  Future<void> addComment(Map<String, dynamic> commentData, String postId) async {
    addCommentCalled = true; // Setta il flag quando viene chiamato
  }
}

/// Fake QuerySnapshot per il mock
class FakeQuerySnapshot implements QuerySnapshot {
  @override
  final List<QueryDocumentSnapshot> docs;

  FakeQuerySnapshot(this.docs);

  // Altri metodi e proprietà non implementati
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake QueryDocumentSnapshot
class FakeQueryDocumentSnapshot implements QueryDocumentSnapshot {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Inizializza il binding per i test di integrazione
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CommentPage Integration Manual Test', () {
    late MockDatabase mockDb;

    setUp(() {
      mockDb = MockDatabase(); // Crea un nuovo mock per ogni test
    });

    testWidgets('Inserimento commento e click send', (WidgetTester tester) async {
      // Costruisci il widget CommentPage con il mock
      await tester.pumpWidget(
        MaterialApp(
          home: CommentPage(
            username: 'TestUser',
            userimage: 'https://example.com/image.png',
            postid: 'post123',
            db: mockDb,
          ),
        ),
      );

      await tester.pumpAndSettle(); // Attendi animazioni e rebuild

      // Trova il campo di testo e inserisci un commento
      final commentField = find.byType(TextField);
      await tester.enterText(commentField, 'Ciao dal test!');
      await tester.pump();

      // Trova il pulsante send e cliccalo
      final sendButton = find.byIcon(Icons.send);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verifica se il metodo addComment del mock è stato chiamato
      expect(mockDb.addCommentCalled, isTrue);
    });
  });
}
