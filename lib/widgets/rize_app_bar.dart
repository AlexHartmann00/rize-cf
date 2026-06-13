
import 'package:flutter/material.dart';

AppBar rizeAppBar = AppBar(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  elevation: 0,
  centerTitle: false,
  toolbarHeight: 82,
  titleSpacing: 20,
  title: Row(
    children: <Widget>[
      Image.asset(
        'assets/brand/Logo transparent.png',
        height: 44,
        fit: BoxFit.contain,
      ),
      const SizedBox(width: 12),
      const Text(
        'RIZE',
        style: TextStyle(
          color: Color(0xFF161A22),
          fontSize: 27,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    ],
  ),
);
