import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:findme_programmazione_mobile/pages/comment.dart';
import 'package:findme_programmazione_mobile/services/database.dart';
import 'comment_page_test.mocks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Genera i mock della classe DatabaseMethods tramite build_runner
@GenerateMocks([DatabaseMethods])
void main() {
  late MockDatabaseMethods mockDb;

  // Dati fittizi per i commenti
  final fakeComments = [
    {"UserName": "Alice", "UserImage": "alice.png", "Comment": "Hello"},
    {"UserName": "Bob", "UserImage": "bob.png", "Comment": "Hi there"},
  ];

  setUp(() {
    mockDb = MockDatabaseMethods();

    // Mock di getComments: ritorna uno stream finto di QuerySnapshot
    when(mockDb.getComments(any)).thenAnswer(
          (_) => Stream.value(FakeQuerySnapshot(fakeComments)),
    );

    // Mock di addComment: non fa nulla, solo per verifica chiamata
    when(mockDb.addComment(any, any)).thenAnswer(
          (_) async {},
    );
  });

  testWidgets(
      "CommentPage Widget Test: inserimento commento e click send",
          (tester) async {
        // Monta il widget CommentPage con il mock
        await tester.pumpWidget(MaterialApp(
          home: CommentPage(
            username: "Tester",
            userimage: "avatar.png",
            postid: "post123",
            db: mockDb,
          ),
        ));

        // Attende che il widget sia completamente renderizzato
        await tester.pumpAndSettle();

        // Trova il TextField dei commenti e inserisci un nuovo commento
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, "Nuovo commento");

        // Trova il pulsante send e cliccalo
        final sendButton = find.byIcon(Icons.send);
        expect(sendButton, findsOneWidget);
        await tester.tap(sendButton);

        // Aggiorna il widget dopo il click
        await tester.pumpAndSettle();

        // Verifica che addComment sia stato chiamato correttamente con i dati giusti
        verify(mockDb.addComment({
          "UserImage": "avatar.png",
          "UserName": "Tester",
          "Comment": "Nuovo commento",
        }, "post123")).called(1);
      });
}

// ==========================================
// Fake QuerySnapshot e DocumentSnapshot per i test
// ==========================================

class FakeDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> dataMap;

  FakeDocumentSnapshot(this.dataMap);

  @override
  Map<String, dynamic> data() => dataMap;

  @override
  dynamic operator [](Object field) => dataMap[field];
}

class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<FakeDocumentSnapshot> docsList;

  FakeQuerySnapshot(List<Map<String, dynamic>> data)
      : docsList = data.map((d) => FakeDocumentSnapshot(d)).toList();

  @override
  List<FakeDocumentSnapshot> get docs => docsList;
}
