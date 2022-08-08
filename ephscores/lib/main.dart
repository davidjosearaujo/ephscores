import 'dart:async';
import 'package:ephscores/components/MenuButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_flashlight/flutter_flashlight.dart';
import 'Burn.dart';
import 'Start.dart';
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
        "/burn": (context) => Burn(),
        "/start": (context) => Start(),
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
  bool wait = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Color.fromRGBO(44, 73, 108, 1.0),
        shadowColor: Colors.transparent,
        title: Text("EPHScores",
          style: TextStyle(
            fontSize: 24,
          )
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: <Widget>[
                      MenuButton(
                        text: "Calculadora de escalas",
                        icon: Icons.person,
                        path: "/scores"
                      ),
                      MenuButton(
                      text: "Avaliação do queimado",
                      icon: Icons.fireplace_outlined,
                      path: "/burn"
                      ),
                      MenuButton(
                      text: "Triagem START",
                      icon: Icons.checklist,
                      path: "/start")
                ]))
          ],
        ),
      ),
    );
  }
}
