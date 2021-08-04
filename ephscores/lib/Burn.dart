import 'package:flutter/material.dart';
import 'Burn/Anterior.dart';
import 'Burn/Posterior.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Burn extends StatefulWidget {
  double ant, pos;
  SharedPreferences prefs;

  @override
  _BurnState createState() => _BurnState();
}

class _BurnState extends State<Burn> {
  int chk = 0;

  refreshAnt(double y) {
    setState(() {
      widget.ant = y;
    });
  }

  refreshPos(double y) {
    setState(() {
      widget.pos = y;
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
        body: Container(
          color: Color.fromRGBO(233, 237, 244, 1),
          child: Column(
            children: [
              Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: AlignmentDirectional.bottomCenter,
                      children: [
                        LinearProgressIndicator(
                          value: (widget.ant + widget.pos) * 0.01,
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
                          })(widget.ant + widget.pos),
                          backgroundColor: Color.fromRGBO(79, 129, 189, 1),
                        ),
                        FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            "${widget.ant + widget.pos}%",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              backgroundColor: Colors.transparent,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
              Expanded(
                flex: 12,
                child:
                    (chk == 0) ? Anterior(refreshAnt) : Posterior(refreshPos),
              )
            ],
          ),
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
