import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flashlight/flutter_flashlight.dart';
import 'STARTList.dart';
import 'Score.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(EPHScores());
}

class EPHScores extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EPHScores',
      initialRoute: '/',
      routes: {
        "/": (context) => EPHScoresPage(),
        "/scores": (context) => Score(),
        //"/START": (context) => START(),
        "/START/List": (context) => STARTList()
      },
      themeMode: ThemeMode.dark,
    );
  }
}

class EPHScoresPage extends StatefulWidget {
  EPHScoresPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _EPHScoresPageState createState() => _EPHScoresPageState();
}

class _EPHScoresPageState extends State<EPHScoresPage> {
  var isSelected = [false, false];
  bool flash = false;
  bool timer = false;

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
                      Navigator.pushNamed(context, "/scores");
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
                      Navigator.pushNamed(context, "/START/List");
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
                            color: !flash
                                ? Colors.white
                                : Color.fromRGBO(44, 73, 108, 1.0),
                            size: 60,
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed))
                                  return Color.fromRGBO(79, 129, 189, 1.0);
                                var color = !flash
                                    ? Color.fromRGBO(79, 129, 189, 1.0)
                                    : Color.fromRGBO(208, 216, 232, 1.0);
                                return color;
                              },
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              !flash
                                  ? Flashlight.lightOff()
                                  : Flashlight.lightOn();
                              flash = !flash;
                            });
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
                            Icons.hourglass_top_rounded,
                            color: !timer
                                ? Colors.white
                                : Color.fromRGBO(44, 73, 108, 1.0),
                            size: 60,
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed))
                                  return Color.fromRGBO(79, 129, 189, 1.0);
                                var color = !timer
                                    ? Color.fromRGBO(79, 129, 189, 1.0)
                                    : Color.fromRGBO(208, 216, 232, 1.0);
                                return color;
                              },
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              timer = !timer;
                            });
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
