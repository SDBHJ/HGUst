import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class StudyExample extends StatefulWidget {
  const StudyExample({Key? key}) : super(key: key);

  @override
  _StudyExampleState createState() => _StudyExampleState();
}

class _StudyExampleState extends State<StudyExample> {
  Timer? _timerA, _timerB, _timerC;
  int _secondsA = 0, _secondsB = 0, _secondsC = 0;
  bool _isRunningA = false, _isRunningB = false, _isRunningC = false;
  int _goal = 1000; // 기본 목표 값
  final _goalController = TextEditingController();
  List<String> _goalAchievers = [];
  int _studyCompleteCount = 0; // 스터디 완료 횟수를 저장할 변수를 선언합니다.
  List<String> _studyResults = []; // 스터디 결과를 저장할 목록을 추가합니다.
  // 시작 날짜와 종료 날짜를 저장할 DateTime 변수를 선언합니다.
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEditing = false; // 목표를 수정 중인지 나타내는 bool 변수

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

  void completeStudy() {
    _studyResults.add(
      '${_studyCompleteCount + 1}번 째 스터디 결과 : ${_goalAchievers.join(', ')} / 목표 시간 : $_goal',
    );

    setState(() {
      _studyCompleteCount++;
      _secondsA = 0;
      _secondsB = 0;
      _secondsC = 0;
      _isRunningA = false;
      _isRunningB = false;
      _isRunningC = false;
    });

    FirebaseFirestore.instance.collection('study').doc('studyexample').update({
      'completeCount': _studyCompleteCount,
      '김철수': _secondsA,
      '홍길동': _secondsB,
      '이한동': _secondsC
    });

    // 이제 _goalAchievers 리스트를 클리어합니다.
    _goalAchievers.clear();
  }

  bool get isStudyCompleted =>
      _secondsA >= _goal &&
      _secondsB >= _goal &&
      _secondsC >= _goal; // 모든 사용자가 스터디를 완료했는지 확인하는 getter를 추가합니다.

  @override
  void dispose() {
    _timerA?.cancel();
    _timerB?.cancel();
    _timerC?.cancel();
    _goalController.dispose();
    super.dispose();
  }

  void startOrPauseTimerA() {
    if (_isRunningA) {
      _timerA?.cancel();
    } else {
      _timerA = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsA++;
        });
        FirebaseFirestore.instance
            .collection('study')
            .doc('studyexample')
            .update({'김철수': _secondsA});
        if (_secondsA >= _goal) {
          _goalAchievers.add('김철수');
          _timerA?.cancel(); // 이 부분을 추가합니다.

          // stopAllTimers();
        }
      });
    }
    setState(() {
      _isRunningA = !_isRunningA;
    });
  }

  void resetTimerA() {
    setState(() {
      _secondsA = 0;
    });
    FirebaseFirestore.instance
        .collection('study')
        .doc('studyexample')
        .update({'김철수': _secondsA});
    _timerA?.cancel();
    _isRunningA = false;
  }

  void startOrPauseTimerB() {
    if (_isRunningB) {
      _timerB?.cancel();
    } else {
      _timerB = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsB++;
        });
        FirebaseFirestore.instance
            .collection('study')
            .doc('studyexample')
            .update({'홍길동': _secondsB});
        if (_secondsB >= _goal) {
          _goalAchievers.add('홍길동');
// stopAllTimers();
          _timerB?.cancel(); // 이 부분을 추가합니다.
        }
      });
    }
    setState(() {
      _isRunningB = !_isRunningB;
    });
  }

  void resetTimerB() {
    setState(() {
      _secondsB = 0;
    });
    FirebaseFirestore.instance
        .collection('study')
        .doc('studyexample')
        .update({'홍길동': _secondsB});
    _timerB?.cancel();
    _isRunningB = false;
  }

  void startOrPauseTimerC() {
    if (_isRunningC) {
      _timerC?.cancel();
    } else {
      _timerC = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsC++;
        });
        FirebaseFirestore.instance
            .collection('study')
            .doc('studyexample')
            .update({'이한동': _secondsC});
        if (_secondsC >= _goal) {
          _goalAchievers.add('이한동');
// stopAllTimers();
          _timerC?.cancel(); // 이 부분을 추가합니다.
        }
      });
    }
    setState(() {
      _isRunningC = !_isRunningC;
    });
  }

  void resetTimerC() {
    setState(() {
      _secondsC = 0;
    });
    FirebaseFirestore.instance
        .collection('study')
        .doc('studyexample')
        .update({'이한동': _secondsC});
    _timerC?.cancel();
    _isRunningC = false;
  }

  void stopAllTimers() {
    _timerA?.cancel();
    _timerB?.cancel();
    _timerC?.cancel();
    _isRunningA = false;
    _isRunningB = false;
    _isRunningC = false;
  }

  void updateGoal() {
    setState(() {
      _goal = int.parse(_goalController.text);
    });
    FirebaseFirestore.instance
        .collection('study')
        .doc('studyexample')
        .update({'goal': _goal});
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    DateTime currentDate = DateTime.now();
    DateTime? picked;

    DateTime? initialDate;
    DateTime? firstDate;

    if (_startDate != null) {
      initialDate = _startDate;
      firstDate = isStart ? currentDate : _startDate!;
    } else {
      initialDate = currentDate;
      firstDate = currentDate;
    }

    picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2025, 12),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color.fromRGBO(70, 130, 180, 1),
            colorScheme: const ColorScheme.light().copyWith(
              primary: Color.fromRGBO(100, 149, 237, 1),
              onPrimary: Colors.white,
              surface: Color.fromRGBO(240, 248, 255, 1),
              onSurface: Colors.black,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStart) {
        setState(() {
          _startDate = picked;
        });
      } else {
        setState(() {
          _endDate = picked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('모바일 앱 개발'),
        backgroundColor: const Color.fromRGBO(100, 215, 251, 1),
        elevation: 5,
        systemOverlayStyle: SystemUiOverlayStyle.light, // 시스템 UI를 어둡게 설정합니다.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                        _startDate == null
                            ? '시작 날짜 선택'
                            : '시작 : ${_startDate!.month}월 ${_startDate!.day}일\n',
                        style: const TextStyle(color: Colors.black)),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                        _endDate == null
                            ? '종료 날짜 선택'
                            : '종료 : ${_endDate!.month}월 ${_endDate!.day}일\n',
                        style: const TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
            buildTimerControls(
                '김철수', startOrPauseTimerA, resetTimerA, _secondsA, _isRunningA),
            buildTimerControls(
                '홍길동', startOrPauseTimerB, resetTimerB, _secondsB, _isRunningB),
            buildTimerControls(
                '이한동', startOrPauseTimerC, resetTimerC, _secondsC, _isRunningC),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '현재 목표: ',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 50, // 원하는 너비로 설정
                  height: 50, // 원하는 높이로 설정
                  child: TextField(
                    style: const TextStyle(fontSize: 30),
                    controller: _goalController,
                    enabled:
                        _isEditing, // _isEditing 변수에 따라 TextField의 활성화 상태를 변경
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blue[200],
                  ),
                  onPressed: () {
                    // 버튼을 누르면 _isEditing을 반전시키고, 필요한 경우 목표를 업데이트
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        updateGoal();
                      }
                    });
                  },
                  child: Text(
                    _isEditing
                        ? '수정하기'
                        : '목표 수정', // _isEditing 변수에 따라 버튼의 텍스트를 변경
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '스터디 완료 횟수: $_studyCompleteCount',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: const Color.fromRGBO(100, 215, 251, 1)),
                  onPressed: () {
                    if (isStudyCompleted) {
                      completeStudy();
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text("정말 스터디를 완료하시겠습니까?"),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("확인"),
                                onPressed: () {
                                  completeStudy();
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text("취소"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text(
                    '스터디 완료하기',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            Divider(),
            for (var result in _studyResults)
              Row(
                children: [
                  const SizedBox(width: 30),
                  Text(result),
                ],
              )
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

  Widget buildTimerControls(String title, VoidCallback onStartOrPause,
      VoidCallback onReset, int seconds, bool isRunning) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 30,
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            Stack(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 30,
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 200,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          width: 200 *
                              (seconds / _goal), // 이 부분은 해당 타이머의 진행도를 표현합니다.
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text('Seconds: $seconds'),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 30,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: const Color.fromRGBO(100, 215, 251, 1)),
                  onPressed: onStartOrPause,
                  child: Text(
                    isRunning ? 'Pause' : 'Start',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: const Color.fromRGBO(100, 215, 251, 1)),
                  onPressed: onReset,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
          ],
        ),
        const SizedBox(
          width: 5,
        ),
        if (title == '김철수' && _secondsA >= _goal)
          Container(
            height: 100,
            width: 100,
            child: const RiveAnimation.asset(
              'assets/images/goal.riv',
            ),
          ),
        if (title == '홍길동' && _secondsB >= _goal)
          Container(
            height: 100,
            width: 100,
            child: const RiveAnimation.asset(
              'assets/images/goal.riv',
            ),
          ),
        if (title == '이한동' && _secondsC >= _goal)
          Container(
            height: 100,
            width: 100,
            child: const RiveAnimation.asset(
              'assets/images/goal.riv',
            ),
          ),
      ],
    );
  }
}
