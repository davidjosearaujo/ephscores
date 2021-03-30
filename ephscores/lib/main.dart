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
      body: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Image.asset('images/EPHScores_logo.png'),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  height: 90,
                  child: ElevatedButton(
                    child: Text(
                      "Calculadora de escalas",
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return Color.fromRGBO(208, 216, 232, 1.0);
                          return Color.fromRGBO(79, 129, 189, 1.0);
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return Color.fromRGBO(44, 73, 108, 1.0);
                          return Colors.white;
                        },
                      ),
                    ),
                    onPressed: () {
                      setState() {}
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  height: 90,
                  child: ElevatedButton(
                    child: Text(
                      "Triagem START",
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return Color.fromRGBO(208, 216, 232, 1.0);
                          return Color.fromRGBO(79, 129, 189, 1.0);
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return Color.fromRGBO(44, 73, 108, 1.0);
                          return Colors.white;
                        },
                      ),
                    ),
                    onPressed: () {
                      setState() {}
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        height: 110,
                        child: ElevatedButton(
                          child: Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 60,
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed))
                                  return Color.fromRGBO(208, 216, 232, 1.0);
                                return Color.fromRGBO(79, 129, 189, 1.0);
                              },
                            ),
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed))
                                  return Color.fromRGBO(44, 73, 108, 1.0);
                                return Colors.white;
                              },
                            ),
                          ),
                          onPressed: () {
                            setState() {}
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        height: 110,
                        child: ElevatedButton(
                          child: Icon(
                            Icons.hourglass_full,
                            color: Colors.white,
                            size: 60,
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed))
                                  return Color.fromRGBO(208, 216, 232, 1.0);
                                return Color.fromRGBO(79, 129, 189, 1.0);
                              },
                            ),
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed))
                                  return Color.fromRGBO(44, 73, 108, 1.0);
                                return Colors.white;
                              },
                            ),
                          ),
                          onPressed: () {
                            setState() {}
                          },
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
