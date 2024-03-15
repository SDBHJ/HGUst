import 'package:flutter/material.dart';
import 'dart:async';

class SelfStudy extends StatefulWidget {
  const SelfStudy({Key? key}) : super(key: key);

  @override
  _SelfStudyState createState() => _SelfStudyState();
}

class _SelfStudyState extends State<SelfStudy> {
  late Timer _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) {
      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  void pauseTimer() {
    _timer.cancel();
  }

  void resetTimer() {
    _timer.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _isTimerRunning = false;
    });
  }

  String getTimerText() {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(1, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours.$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('셀프 스터디'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Timer: ${getTimerText()}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _isTimerRunning = !_isTimerRunning;
                      if (_isTimerRunning) {
                        startTimer();
                      } else {
                        pauseTimer();
                      }
                    });
                  },
                  child: Text(
                    _isTimerRunning ? 'Pause' : 'Start',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    resetTimer();
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
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
