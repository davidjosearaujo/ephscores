import 'dart:async';
import 'package:ephscores/components/MenuButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Burn.dart';
import 'PediatricScore.dart';
import 'Start.dart';
import 'Score.dart';
import 'Contacts.dart';

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
        "/contacts": (context) => Contacts(),
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
  bool wait = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          child: Image(
            image: AssetImage("assets/EPHScores_logo.png"),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color.fromRGBO(44, 73, 108, 1.0),
        shadowColor: Colors.transparent,
        title: Text(
          "EPHScores",
          style: TextStyle(
            fontSize: 30,
          ),
        ),
      ),
      body: SafeArea(
        minimum: EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
            Expanded(
              child: MenuButton(
                  text: "Escalas Gerais",
                  icon: Icons.person,
                  onPressed: () {
                    Navigator.pushNamed(context, "/scores");
                  }),
            ),
            Expanded(
              child: MenuButton(
                  text: "Escalas Pediátricas",
                  icon: Icons.child_care,
                  onPressed: () {
                    Navigator.pushNamed(context, "/ped_scores");
                  }),
            ),
            Expanded(
              child: MenuButton(
                  text: "Avaliação Queimado",
                  icon: Icons.local_fire_department,
                  onPressed: () {
                    Navigator.pushNamed(context, "/burn");
                  }),
            ),
            Expanded(
              child: MenuButton(
                  text: "Triagem START",
                  icon: Icons.groups,
                  onPressed: () {
                    Navigator.pushNamed(context, "/start");
                  }),
            ),
            Expanded(
              child: MenuButton(
                  text: "Contactos Importantes",
                  icon: Icons.phone,
                  onPressed: () {
                    Navigator.pushNamed(context, "/contacts");
                  }),
            )
          ]),
        ),
      ),
    );
  }
}
