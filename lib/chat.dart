import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatRoom extends StatelessWidget {
  final List<String> selectedSubjects;

  const ChatRoom({Key? key, required this.selectedSubjects}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('과목 채팅방'),
        backgroundColor: const Color.fromRGBO(100, 215, 251, 1),
        elevation: 5,
        systemOverlayStyle: SystemUiOverlayStyle.light, // 시스템 UI를 어둡게 설정합니다.
      ),
      body: ListView.builder(
        itemCount: selectedSubjects.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(selectedSubjects[index]),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.lightBlue),
              onPressed: () async {
                CollectionReference subjects =
                    FirebaseFirestore.instance.collection('chatrooms');
                DocumentReference docRef =
                    subjects.doc('${selectedSubjects[index]}');

                await docRef.set({
                  'message': [],
                }, SetOptions(merge: true));

                // ignore: use_build_context_synchronously
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagePage(
                      subject: '${selectedSubjects[index]}',
                    ),
                  ),
                );
              },
              child: const Text(
                '대화하기',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MessagePage extends StatefulWidget {
  final String subject;

  const MessagePage({Key? key, required this.subject}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  CollectionReference messages =
      FirebaseFirestore.instance.collection('chatrooms');
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late Stream<List<types.Message>> messageStream;

  @override
  void initState() {
    super.initState();
    messageStream = messages
        .doc(widget.subject)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots()
        .map(_handleSnapshot);
  }

  List<types.Message> _handleSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['time'] as Timestamp;
      return types.TextMessage(
        id: doc.id,
        author: types.User(id: data['user']),
        createdAt: timestamp.millisecondsSinceEpoch,
        text: data['message'],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.subject),
        backgroundColor: Colors.blueGrey,
        elevation: 5,
        systemOverlayStyle: SystemUiOverlayStyle.light, // 시스템 UI를 어둡게 설정합니다.
      ),
      body: StreamBuilder<List<types.Message>>(
        stream: messageStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Chat(
            messages: snapshot.data ?? [],
            onSendPressed: (types.PartialText message) {
              final messageText = message.text;

              FirebaseFirestore.instance
                  .collection('chatrooms')
                  .doc(widget.subject)
                  .collection('messages')
                  .doc() // 새 문서 ID를 자동 생성합니다.
                  .set({
                'message': messageText, // 'message' 필드에 메시지 텍스트를 저장합니다.
                'user': currentUser!.uid, // 'user' 필드에 현재 사용자의 UID를 저장합니다.
                'time':
                    FieldValue.serverTimestamp(), // 'time' 필드에 서버 타임스탬프를 저장합니다.
              });
            },
            user: types.User(id: currentUser!.uid),
          );
        },
      ),
    );
  }
}
