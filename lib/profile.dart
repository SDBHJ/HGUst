import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> getUserData() async {
  User? user = FirebaseAuth.instance.currentUser; // 현재 로그인한 사용자를 가져옵니다.
  if (user == null) {
    throw Exception(
        'No user is currently signed in!'); // 사용자가 로그인하지 않았다면 예외를 발생시킵니다.
  }
  DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  String email = doc.get('email');
  String nickname = doc.get('nickname');
  return {'email': email, 'nickname': nickname};
}

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);

  final List<String> _routeNames = [
    '/study',
    '/home',
    '/profile',
  ];

  final int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    void _onItemTapped(int index) {
      if (_selectedIndex != index) {
        Navigator.of(context, rootNavigator: true)
            .pushNamed(_routeNames[index]);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        backgroundColor: const Color.fromRGBO(100, 215, 251, 1),
        elevation: 5,
        systemOverlayStyle: SystemUiOverlayStyle.light, // 시스템 UI를 어둡게 설정합니다.
      ),
      body: FutureBuilder(
        future: getUserData(), // 'uid'를 제거하고, getUserData 함수를 직접 호출합니다.
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
                    'An error occurred: ${snapshot.error}')); // 오류 메시지를 표시합니다.
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Image.network(
                        'https://i.namu.wiki/i/Bge3xnYd4kRe_IKbm2uqxlhQJij2SngwNssjpjaOyOqoRhQlNwLrR2ZiK-JWJ2b99RGcSxDaZ2UCI7fiv4IDDQ.webp'),
                  ),
                  SizedBox(height: 10),
                  Text('Email: ${snapshot.data!['email']}'),
                  Text('닉네임: ${snapshot.data!['nickname']}'),
                  SizedBox(height: 20),
                  // 학기 정보를 GridView로 추가합니다.
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2, // 열의 수를 설정합니다. 원하는 대로 조절 가능합니다.
                      childAspectRatio:
                          3.0, // 항목의 너비 대 높이 비율을 설정합니다. 이 값을 조절하여 항목의 크기를 변경할 수 있습니다.
                      children: <Widget>[
                        Card(
                          color: Colors.lightBlue[50],
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('2021-1학기'), Text('더보기')])),
                        ),
                        Card(
                          color: Colors.lightBlue[50],
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('2021-2학기'), Text('더보기')])),
                        ),
                        Card(
                          color: Colors.lightBlue[50],
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('2022-1학기'), Text('더보기')])),
                        ),
                        Card(
                          color: Colors.lightBlue[50],
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('2022-2학기'), Text('더보기')])),
                        ),
                        Card(
                          color: Colors.lightBlue[50],
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('2023-1학기'), Text('더보기')])),
                        ),
                        Card(
                          color: Colors.lightBlue[50],
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Text('2023-2학기'), Text('더보기')])),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.supervisor_account_outlined),
              activeIcon: Icon(Icons.supervised_user_circle),
              label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_sharp),
              label: ''),
          BottomNavigationBarItem(
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
