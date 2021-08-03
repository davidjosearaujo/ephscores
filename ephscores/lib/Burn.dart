import 'package:flutter/material.dart';
import 'Burn/Anterior.dart';
import 'Burn/Posterior.dart';

class Burn extends StatefulWidget {
  @override
  _BurnState createState() => _BurnState();
}

class _BurnState extends State<Burn> {
  int chk = 0;
  double perc = 0;

  refreshSev(double y) {
    setState(() {
      perc = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Queimado - ${perc}",
            style: TextStyle(fontSize: 24),
          ),
          backgroundColor: Color.fromRGBO(79, 129, 189, 1.0),
          actions: [
            IconButton(
              icon: Icon(Icons.replay),
              onPressed: () {},
            ),
          ],
        ),
        body: (chk == 0) ? Anterior(refreshSev) : Posterior(),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
          selectedItemColor: Color.fromRGBO(79, 129, 189, 1.0),
          unselectedItemColor: Color.fromRGBO(44, 73, 108, 1.0),
          iconSize: 30,
          currentIndex: chk,
          onTap: (int e) {
            setState(() {
              chk = e;
            });
          },
          items: [
            BottomNavigationBarItem(
              title: Text("Plano anterior"),
              icon: Icon(Icons.accessibility),
            ),
            BottomNavigationBarItem(
              title: Text("Plano posterior"),
              icon: Icon(Icons.accessibility),
            ),
          ],
        ));
  }
}
