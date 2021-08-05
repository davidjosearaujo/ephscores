import 'package:flutter/material.dart';
import 'Burn/Anterior.dart';
import 'Burn/Posterior.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class Burn extends StatefulWidget {
  @override
  _BurnState createState() => _BurnState();
}

class _BurnState extends State<Burn> {
  final RefreshController controllerPos = RefreshController();
  final RefreshController controllerAnt = RefreshController();
  SharedPreferences _prefs;
  double _antc = 0, _posc = 0;
  int _chk = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      setState(() {
        _antc = value.containsKey("antc") ? value.getDouble("antc") : 0;
        _posc = value.containsKey("posc") ? value.getDouble("posc") : 0;
      });
    });
  }

  refreshAnt(double y) async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _antc = y;
      _prefs.setDouble("antc", _antc);
    });
  }

  refreshPos(double y) async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _posc = y;
      _prefs.setDouble("posc", _posc);
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
              icon: Icon(Icons.delete),
              onPressed: () async {
                _prefs = await SharedPreferences.getInstance();
                setState(() {
                  if (_chk == 0) {
                    _prefs.remove("head_front");
                    _prefs.remove("right_arm_front");
                    _prefs.remove("upper_torso_front");
                    _prefs.remove("lower_torso_front");
                    _prefs.remove("genitals_front");
                    _prefs.remove("left_arm_front");
                    _prefs.remove("right_leg_front");
                    _prefs.remove("left_leg_front");
                    _prefs.remove("antc");
                    _antc = 0;
                    controllerAnt.method();
                  } else {
                    _prefs.remove("head_back");
                    _prefs.remove("right_arm_back");
                    _prefs.remove("upper_torso_back");
                    _prefs.remove("lower_torso_back");
                    _prefs.remove("left_arm_back");
                    _prefs.remove("right_leg_back");
                    _prefs.remove("left_leg_back");
                    _prefs.remove("posc");
                    _posc = 0;
                    controllerPos.method();
                  }
                });
                SnackBar snackBar = SnackBar(
                  backgroundColor: Color.fromRGBO(44, 73, 108, 0.70),
                  content: Text(
                    'Plano ${(() {
                      if (_chk == 0) {
                        return "anterior";
                      } else {
                        return "posterior";
                      }
                    })()} limpo',
                    textAlign: TextAlign.center,
                  ),
                  duration: Duration(milliseconds: 800),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
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
                          value: (_antc + _posc) * 0.01,
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
                          })(_antc + _posc),
                          backgroundColor: Color.fromRGBO(79, 129, 189, 1),
                        ),
                        FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            "${_antc + _posc}%",
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
                child: (_chk == 0)
                    ? Anterior(refreshAnt, _antc, _prefs, controllerAnt)
                    : Posterior(refreshPos, _posc, _prefs, controllerPos),
              )
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
          selectedItemColor: Color.fromRGBO(79, 129, 189, 1.0),
          unselectedItemColor: Color.fromRGBO(44, 73, 108, 1.0),
          iconSize: 30,
          currentIndex: _chk,
          onTap: (int e) {
            setState(() {
              _chk = e;
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

class RefreshController {
  void Function() method;
}
