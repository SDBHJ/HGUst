import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;
import 'chat.dart';
import 'study.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Task(),
    );
  }
}

class Task extends StatefulWidget {
  const Task({Key? key}) : super(key: key);

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  Uint8List? _imageBytes;
  final ImagePicker picker = ImagePicker();
  String scannedText = "";
  bool isLoading = false;
  String? userId;
  Image? _image;
  List<bool> selected = []; // 클래스의 멤버 변수로 이동

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      print("Firebase initialized");
      setState(() {});
    });
    userId = FirebaseAuth.instance.currentUser!.uid; // 현재 사용자의 UID를 가져옵니다.
  }

  Future getImage() async {
    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.length == 1) {
          final file = files[0];
          final reader = html.FileReader();

          reader.onLoadEnd.listen((e) {
            setState(() {
              String result = reader.result as String;
              String base64 = result.substring(result.indexOf(',') + 1);
              _imageBytes = base64Decode(base64);
              isLoading = true;
            });
            getRecognizedText(_imageBytes!);
          });

          reader.readAsDataUrl(file);
        }
      });
    } else {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        _imageBytes = await imageFile.readAsBytes();

        // 모바일에서도 base64 문자열로 변환
        String img64 = base64Encode(_imageBytes!);

        FirebaseStorage storage = FirebaseStorage.instance;
        Reference ref = storage.ref().child("images/$userId.jpg");
        UploadTask uploadTask = ref.putString(img64,
            format: PutStringFormat.base64); // base64 문자열을 업로드
        await uploadTask.whenComplete(() async {
          final String downloadUrl = await ref.getDownloadURL();
          setState(() {
            _image = Image.network(downloadUrl);
            isLoading = true;
          });
        });

        getRecognizedText(_imageBytes!);
      }
    }
  }

  void getRecognizedText(Uint8List imageBytes) async {
    setState(() {
      isLoading = true; // 텍스트 인식을 시작할 때 로딩 상태를 true로 설정
    });

    try {
      String img64 = base64Encode(imageBytes);

      var url = 'https://api.ocr.space/parse/image';
      var payload = {
        "base64Image": "data:image/jpg;base64,$img64",
        "language": "kor"
      };
      var header = {"apikey": "K81351340088957"};

      var post =
          await http.post(Uri.parse(url), body: payload, headers: header);
      var result = jsonDecode(post.body);

      List<String> recognizedTexts = result['ParsedResults'][0]['ParsedText']
          .split('\r\n'); // 줄바꿈으로 텍스트를 분리

      // 인식된 텍스트 중 '과목명(강의번호)'
      RegExp pattern = RegExp(r'^.*\(\d{2}\)$'); // '과목명(강의번호)' 패턴의 정규 표현식
      List<String> filteredTexts = recognizedTexts
          .where((text) => pattern.hasMatch(text))
          .take(8) // 처음 8개의 텍스트만 추출

          .toSet() // 중복 제거
          .toList();

      filteredTexts = filteredTexts
          .map((text) => '$text)')
          .toList(); //닫는 괄호 추가 이거 없으면 닫는 괄호가 없음
      List<String> texts = [];
      for (int i = 0; i < filteredTexts.length && texts.length < 8; i++) {
        texts.add('${filteredTexts[i]}'); // 닫는 괄호 추가
      }
      setState(() {
        scannedText = filteredTexts.join(' ');
        selected =
            List.filled(texts.length, false); // 텍스트 리스트의 크기를 기준으로 선택 상태 초기화
        isLoading = false; // 텍스트 인식이 완료되면 로딩 상태를 false로 설정
      });

// Firestore에 사용자별 데이터를 저장하는 코드
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      DocumentReference userDocRef = users.doc(userId);

// 사용자 문서에 'subject' 필드를 배열로 추가하고 인식된 텍스트를 저장
      userDocRef.set({
        'Subject': FieldValue.arrayUnion(filteredTexts),
      }, SetOptions(merge: true)); // 이미 문서가 존재하면 'Subject' 필드만 업데이트

// Firestore에 인식된 텍스트별 데이터를 저장하는 코드
      CollectionReference subjects =
          FirebaseFirestore.instance.collection('subject');
      for (String text in filteredTexts) {
        // 'text' 값을 문서 ID로 사용
        DocumentReference docRef = subjects.doc(text);

        // 문서가 이미 존재하는지 확인
        DocumentSnapshot docSnapshot = await docRef.get();
        if (!docSnapshot.exists) {
          // 문서가 존재하지 않으면 새로 생성
          docRef.set({
            'Subject': text, // 필드 이름과 저장할 텍스트를 설정
            'uid': [userId], // 현재 사용자의 UID를 배열에 저장
          });
        } else {
          // 문서가 이미 존재하면 uid 배열에 현재 사용자의 UID 추가
          docRef.update({
            'uid': FieldValue.arrayUnion([userId])
          });
        }
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false; // 오류가 발생하면 로딩 상태를 false로 설정
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30, width: double.infinity),
              _image != null ? _image! : Container(),
              _buildRecognizedText(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(),
                  const SizedBox(
                    width: 30,
                  ),
                  _buildConfirmButton(),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '시간표 업로드 이후 원하는 과목\n 체크해서 확인을 눌러주세요:)',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyRoom(),
                      ),
                    );
                  },
                  child: const Text(
                    "공부하기",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecognizedText() {
    if (isLoading) {
      return const CircularProgressIndicator();
    } else if (selected.isEmpty) {
      // selected 리스트가 비어있을 경우 아무것도 반환하지 않음
      return Container();
    } else {
      // 인식된 텍스트를 리스트로 변환
      List<String> texts = scannedText.split(') ');

      // 각 텍스트를 CheckboxListTile으로 변환
      List<Widget> buttons = List<Widget>.generate(texts.length, (index) {
        return CheckboxListTile(
          title: Text(texts[index]),
          value: selected[index],
          activeColor: Colors.blueAccent,
          onChanged: (bool? value) {
            setState(() {
              selected[index] = value!;
            });

            // Firestore에 사용자별 데이터를 저장하는 코드
            CollectionReference users =
                FirebaseFirestore.instance.collection('users');
            DocumentReference userDocRef = users.doc(userId);

            if (value == true) {
              // 체크박스가 선택된 경우, 해당 텍스트를 'Subject' 필드에 추가
              userDocRef.update({
                'Subject': FieldValue.arrayUnion([texts[index]]),
              });
            } else {
              // 체크박스가 해제된 경우, 해당 텍스트를 'Subject' 필드에서 제거
              userDocRef.update({
                'Subject': FieldValue.arrayRemove([texts[index]]),
              });
            }
          },
        );
      });

      // 체크박스 리스트를 Column 위젯으로 묶어 반환
      return Column(
        children: buttons,
      );
    }
  }

  Widget _buildButton() {
    return SizedBox(
      height: 50,
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color.fromRGBO(100, 215, 251, 1), // Background color
        ),
        onPressed: () {
          getImage();
        },
        child: const Text(
          "갤러리",
          style: TextStyle(
              color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    List<String> selectedSubjects = [];
    for (int i = 0; i < selected.length; i++) {
      if (selected[i]) {
        selectedSubjects.add(scannedText.split(') ')[i]);
      }
    }

    return SizedBox(
      height: 50,
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color.fromRGBO(100, 215, 251, 1), // Background color
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatRoom(selectedSubjects: selectedSubjects),
            ),
          );
        },
        child: const Text(
          "확인",
          style: TextStyle(
              color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
