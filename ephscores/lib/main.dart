import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPH Scores',
      themeMode: ThemeMode.dark,
      home: MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var isSelected = [false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Image.asset('images/EPHScores_logo.png'),
          ),
          Column(
            children: [
              ToggleButtons(
                direction: Axis.vertical,
                renderBorder: false,
                color: Colors.black,
                fillColor: Color.fromRGBO(79, 129, 189, 1.0),
                splashColor: Color.fromRGBO(208, 216, 232, 1.0),
                children: <Widget>[
                  Text("Calculadora de escalas"),
                  Text("Triagem START"),
                ],
                onPressed: (int index) {
                  setState(() {
                    isSelected[index] = isSelected[index];
                  });
                },
                isSelected: isSelected,
              )
            ],
          ),
        ],
      ),
    );
  }
}
