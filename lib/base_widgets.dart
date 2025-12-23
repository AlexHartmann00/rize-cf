import 'package:rize/globals.dart' as globals;
import 'package:rize/main.dart' show HomePageSlotMachineWidget, WorkoutLibraryPage;
import 'package:flutter/material.dart';

class RizeScaffold extends StatefulWidget {
  Widget body;
  BottomNavigationBar? bottomNavigationBar;
  AppBar? appBar;
  RizeScaffold({super.key, required this.body, this.bottomNavigationBar, this.appBar});

  @override
  State<RizeScaffold> createState() => _RizeScaffoldState();
}

class _RizeScaffoldState extends State<RizeScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      bottomNavigationBar: widget.bottomNavigationBar,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.3,
            focal: Alignment.topLeft,
            stops: [0, 0.88,1],
            colors: [Colors.blue.shade200, Colors.blue.shade900, Colors.black],
          )//LinearGradient(colors: [Theme.of(context).primaryColor, Color(0xaa72c6ef)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
        ),
        child: Stack(
          children: [
            Center(child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.55,
              child:Image.asset('assets/brand/rize_logo_r.png', color: Colors.white.withAlpha(50),))),
            widget.body,
          ],
        ))
    );
  }
}