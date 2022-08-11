import 'dart:async';
import 'package:ephscores/components/MenuButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_flashlight/flutter_flashlight.dart';
import 'Burn.dart';
import 'PediatricScore.dart';
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
        "/ped_scores": (context) => PediatricScore(),
        //"/phone_book": (context) => PhoneBook(),
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                child: Image(
                  image: AssetImage("assets/EPHScores_logo.png"),
                  width: 250,
                  height: 250,
                ),
              ),
              Expanded(
                  child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20.0,
                      runSpacing: 20.0,
                      children: <Widget>[
                    MenuButton(
                        text: "Escalas",
                        icon: Icons.person,
                        onPressed: () {
                          Navigator.pushNamed(context, "/scores");
                        }),
                    MenuButton(
                        text: "Escalas Pediátricas",
                        icon: Icons.child_care,
                        onPressed: () {
                          Navigator.pushNamed(context, "/ped_scores");
                        }),
                    MenuButton(
                        text: "Avaliação Queimado",
                        icon: Icons.local_fire_department,
                        onPressed: () {
                          Navigator.pushNamed(context, "/burn");
                        }),
                    MenuButton(
                        text: "Triagem START",
                        icon: Icons.checklist,
                        onPressed: () {
                          Navigator.pushNamed(context, "/start");
                        }),
                    MenuButton(
                        text: "Contactos", 
                        icon: Icons.phone, 
                        onPressed: () {
                          Navigator.pushNamed(context, "/phone_book");
                        })
                  ]))
            ],
          ),
        ),
      ),
    );
  }
}
