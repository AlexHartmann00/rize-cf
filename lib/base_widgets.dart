import 'package:flutter/material.dart';

class RizeScaffold extends StatefulWidget {
  const RizeScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
  });

  final Widget body;
  final BottomNavigationBar? bottomNavigationBar;
  final AppBar? appBar;

  @override
  State<RizeScaffold> createState() => _RizeScaffoldState();
}

class _RizeScaffoldState extends State<RizeScaffold> {
  @override
  Widget build(BuildContext context) {
    final double backgroundOffset = widget.bottomNavigationBar == null
        ? 0
        : (kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom) /
              2;
    return Scaffold(
      appBar: widget.appBar,
      bottomNavigationBar: widget.bottomNavigationBar,
      backgroundColor: Colors.transparent,
      body: Container(
        key: const ValueKey<String>('rize-background'),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.3,
            focal: Alignment.topLeft,
            stops: [0, 0.55, 1],
            colors: [Colors.blue.shade200, Colors.blue.shade900, Colors.black],
          ), //LinearGradient(colors: [Theme.of(context).primaryColor, Color(0xaa72c6ef)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, backgroundOffset),
                child: Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 0.55,
                    child: Image.asset(
                      'assets/brand/rize_logo_r.png',
                      fit: BoxFit.contain,
                      color: Colors.white.withAlpha(50),
                    ),
                  ),
                ),
              ),
            ),
            widget.body,
          ],
        ),
      ),
    );
  }
}
