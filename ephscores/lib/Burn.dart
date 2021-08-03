import 'package:flutter/material.dart';
import 'Burn/Anterior.dart';
import 'Burn/Posterior.dart';

class Burn extends StatefulWidget {
  @override
  _BurnState createState() => _BurnState();
}

class _BurnState extends State<Burn> {
  int chk = 0;
  double _perc = 0;

  refreshSev(double y) {
    setState(() {
      _perc = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Queimado",
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
        body: Column(
          children: [
            Expanded(
                flex: 12,
                child: (chk == 0) ? Anterior(refreshSev) : Posterior()),
            Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      LinearProgressIndicator(
                        value: _perc * 0.01,
                        color: ((double e) {
                          if (e > 32) {
                            return Color.fromRGBO(234, 67, 53, 1);
                          } else if (e > 16) {
                            return Color.fromRGBO(255, 153, 51, 1);
                          } else if (e > 0) {
                            return Color.fromRGBO(251, 188, 4, 1);
                          } else {
                            return Color.fromRGBO(79, 129, 189, 1);
                          }
                        })(_perc),
                        backgroundColor: Color.fromRGBO(79, 129, 189, 1),
                      ),
                      Text(
                        "${_perc}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          backgroundColor: Colors.transparent,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 2,
                        ),
                      )
                    ],
                  ),
                ))
          ],
        ),
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
