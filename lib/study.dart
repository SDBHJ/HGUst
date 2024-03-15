import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:moapp_project/modules/face_detector_gallery/views/face_detector_gallery_view.dart';
import 'package:moapp_project/modules/home/controllers/home_controller.dart';
import 'dart:async';
import 'studyexample.dart';

class StudyRoom extends StatefulWidget {
  const StudyRoom({Key? key}) : super(key: key);

  @override
  _StudyRoomState createState() => _StudyRoomState();
}

class _StudyRoomState extends State<StudyRoom> {
  Map<String, bool> _selectedUsers = {};

  final Map<String, bool> _appliedSubjects = {};
  String? selectedSubject;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _routeNames = [
    '/study',
    '/home',
    '/profile',
  ];

  final int _selectedIndex = 0;
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      Navigator.of(context, rootNavigator: true).pushNamed(_routeNames[index]);
    }
  }

  Future<String> getNickname(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc['nickname'];
  }

  Future<List<String>> getAppliedUsers(String subject) async {
    final doc = await _firestore.collection('study').doc(subject).get();
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<String> appliedUsers = [];

    for (var entry in data.entries) {
      if (entry.value == true) {
        final nickname = await getNickname(entry.key);
        appliedUsers.add(nickname);
      }
    }

    return appliedUsers;
  }

  Future<List<String>> getSubjects() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception("No current user");
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    final allSubjects = List<String>.from(doc['Subject']);

    final subjects = allSubjects.sublist(0, min(6, allSubjects.length));

    return subjects;
  }

  Widget buildSubjects() {
    return FutureBuilder<List<String>>(
      future: getSubjects(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 5 / 4, //5/6이었음
              children: snapshot.data!.asMap().entries.map((entry) {
                String subject = entry.value;
                return Card(
                  color: Colors.lightBlue[50],
                  child: Column(
                    children: [
                      ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Text('#$index ',
                                //     style: TextStyle(fontSize: 15)),
                                Text(subject,
                                    style: const TextStyle(fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        child: Text(_appliedSubjects[subject] ?? false
                            ? '스터디 취소하기'
                            : '스터디 신청하기'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: () {
                          String uid = _auth.currentUser?.uid ?? '';
                          bool isApplied = _appliedSubjects[subject] ?? false;

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Theme(
                                data: ThemeData(
                                    dialogBackgroundColor: Colors.white),
                                child: AlertDialog(
                                  title: Text(isApplied ? '스터디 취소' : '스터디 신청'),
                                  content: Text(isApplied
                                      ? '정말로 스터디를 취소하겠습니까?'
                                      : '정말로 스터디를 신청하겠습니까?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('아니오',
                                          style:
                                              TextStyle(color: Colors.black)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('예',
                                          style:
                                              TextStyle(color: Colors.black)),
                                      onPressed: () async {
                                        setState(() {
                                          _appliedSubjects[subject] =
                                              !isApplied;
                                        });

                                        await _firestore
                                            .collection('study')
                                            .doc(subject)
                                            .set({
                                          uid: !isApplied,
                                          'count': FieldValue.increment(
                                              isApplied ? -1 : 1),
                                        }, SetOptions(merge: true));

                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            child: const Text(
                              '신청현황 보기',
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () async {
                              List<String> appliedUsers =
                                  await getAppliedUsers(subject);

                              // ignore: use_build_context_synchronously
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text('신청 현황'),
                                    content: Column(
                                      children: [
                                        ...appliedUsers
                                            .map((user) => UserCheckbox(
                                                  user: user,
                                                  value: _selectedUsers[user] ??
                                                      false,
                                                  onChanged: (value) {
                                                    _selectedUsers[user] =
                                                        value;
                                                  },
                                                ))
                                            .toList(),
                                        const SizedBox(height: 20),
                                        const Text('참고사항'),
                                        const SizedBox(
                                          width: 230,
                                          child: Text(
                                            '1. 스터디원은 3주차 월요일 3~5명 랜덤 배정됩니다.',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 230,
                                            child: Text(
                                              '2. 함께하고 싶은 학생이 있으면 체크박스 눌러주세요.',
                                              style: TextStyle(fontSize: 10),
                                            )),
                                        const SizedBox(
                                            width: 230,
                                            child: Text(
                                              '3. 학생 서로 체크박스를 눌러야 매칭이 됩니다.',
                                              style: TextStyle(fontSize: 10),
                                            )),
                                      ],
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('study')
                                .doc(subject)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                int count = snapshot.data!['count'] ?? 0;
                                return Text(
                                  '신청인원: $count',
                                  style: const TextStyle(fontSize: 16),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                return const CircularProgressIndicator();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Study Room'),
        backgroundColor: const Color.fromRGBO(100, 215, 251, 1),
        elevation: 5,
        systemOverlayStyle: SystemUiOverlayStyle.light, // 시스템 UI를 어둡게 설정합니다.
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSubjects(),
            Row(
              children: [
                Container(
                  height: 150,
                  width: 215,
                  child: Card(
                    color: Colors.lightBlue[50],
                    child: Column(
                      children: [
                        Text('\nStudy Example\n'),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // 배경색을 blue로 설정
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StudyExample(),
                              ),
                            );
                          },
                          child: Text(
                            '스터디하기',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 150,
                  width: 215,
                  child: Card(
                    color: Colors.lightBlue[50],
                    child: Column(
                      children: [
                        Text('\n혼자 공부하기\n'),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // 배경색을 blue로 설정
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  Get.put(
                                      HomeController()); // HomeController 초기화
                                  return const FaceDetectorGalleryView();
                                },
                              ),
                            );
                          },
                          child: Text(
                            '혼자 공부하기',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ignore: prefer_const_literals_to_create_immutables
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.supervisor_account_outlined),
              activeIcon: Icon(Icons.supervised_user_circle),
              label: ''),
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_sharp),
              label: ''),
          const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: ''),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class UserCheckbox extends StatefulWidget {
  final String user;
  final bool value;
  final ValueChanged<bool> onChanged;

  UserCheckbox(
      {required this.user, required this.value, required this.onChanged});

  @override
  _UserCheckboxState createState() => _UserCheckboxState();
}

class _UserCheckboxState extends State<UserCheckbox> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.user),
        Row(
          children: [
            const Text('함께하기'), // 추가된 텍스트 위젯
            Checkbox(
              value: _value,
              onChanged: (value) {
                setState(() {
                  _value = value!;
                });
                widget.onChanged(value!);
              },
            ),
          ],
        ),
      ],
    );
  }
}
