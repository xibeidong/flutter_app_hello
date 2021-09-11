import 'package:flutter/material.dart';
import 'package:app_hello/custom/random_word.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'RandomNum',
        theme: ThemeData(primaryColor: Colors.white), //不管用，不知道什么原因
        home: const RandomWords()
    );
  }
}
