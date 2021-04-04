import 'package:ephscores/Scores/Cincinnati.dart';
import 'package:ephscores/Scores/ECG.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Scores/MGAP.dart';

// ignore: must_be_immutable
class Score extends StatefulWidget {
  SharedPreferences prefs1;

  Score();

  @override
  _ScoreState createState() => _ScoreState();
}

class _ScoreState extends State<Score> {
  List<bool> expanded = List<bool>.filled(8, false);
  List<bool> cincinnati = List<bool>.filled(3, false);
  List<int> ecg = List<int>.filled(3, 0);
  List<int> mgap = List<int>.filled(3, -1);
  int cin = 0;
  int ecgc = 3;
  int mgapc = 3;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    SharedPreferences.getInstance().then((value) {
      setState(() {
        cincinnati[0] =
            value.containsKey('s1.0') ? value.getBool('s1.0') : false;
        cincinnati[1] =
            value.containsKey('s1.1') ? value.getBool('s1.1') : false;
        cincinnati[2] =
            value.containsKey('s1.2') ? value.getBool('s1.2') : false;
        ecg[0] = value.containsKey('s2.0') ? value.getInt('s2.0') : 0;
        ecg[1] = value.containsKey('s2.1') ? value.getInt('s2.1') : 0;
        ecg[2] = value.containsKey('s2.2') ? value.getInt('s2.2') : 0;
        mgap[0] = value.containsKey('s3.0') ? value.getInt('s3.0') : -1;
        mgap[1] = value.containsKey('s3.1') ? value.getInt('s3.1') : -1;
        mgap[2] = value.containsKey('s3.2') ? value.getInt('s3.2') : -1;
      });
    });
  }

  Future<void> cincinattiCallback(List<bool> i) async {
    cin = 0;
    for (bool x in i) {
      if (x) cin++;
    }
    widget.prefs1 = await SharedPreferences.getInstance();
    widget.prefs1.setBool("s1.0", i[0]);
    widget.prefs1.setBool("s1.1", i[1]);
    widget.prefs1.setBool("s1.2", i[2]);
    setState(() {});
  }

  Future<void> ecgCallback(List<int> i) async {
    if (i[0] == 0 && i[1] == 0 && i[2] == 0) {
      ecgc = 3;
    } else {
      ecgc = i[0] + i[1] + i[2];
    }
    widget.prefs1 = await SharedPreferences.getInstance();
    widget.prefs1.setInt('s2.0', ecg[0]);
    widget.prefs1.setInt('s2.1', ecg[1]);
    widget.prefs1.setInt('s2.2', ecg[2]);
  }

  Future<void> mgapCallback(List<int> i) async {
    mgapc = ecgc;
    for (int x in i) {
      if (x != -1) mgapc += x;
    }
    widget.prefs1 = await SharedPreferences.getInstance();
    widget.prefs1.setInt('s3.0', mgap[0]);
    widget.prefs1.setInt('s3.1', mgap[1]);
    widget.prefs1.setInt('s3.2', mgap[2]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Escalas",
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(79, 129, 189, 1.0),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              widget.prefs1 = await SharedPreferences.getInstance();
              widget.prefs1.clear();
              load();
            },
          ),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                expanded[index] = !expanded[index];
              });
            },
            expandedHeaderPadding: EdgeInsets.all(0),
            children: [
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    title: Text(
                      "Cincinnati",
                      style: TextStyle(
                          color: Color.fromRGBO(44, 73, 108, 1.0),
                          fontSize: 18),
                    ),
                    trailing: Text(
                      "${cin}",
                      style: TextStyle(
                        color: ((int e) {
                          if (e == 0) {
                            return Color.fromRGBO(52, 168, 83, 1.0);
                          }
                          return (e > 2)
                              ? Color.fromRGBO(234, 67, 53, 1.0)
                              : Color.fromRGBO(251, 188, 4, 1.0);
                        })(cin),
                        fontSize: 36,
                      ),
                    ),
                  );
                },
                backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                isExpanded: expanded[0],
                canTapOnHeader: true,
                body: (() {
                  return Cincinnati(cincinattiCallback, cincinnati);
                })(),
              ),
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    title: Text(
                      "ECG",
                      style: TextStyle(
                          color: Color.fromRGBO(44, 73, 108, 1.0),
                          fontSize: 18),
                    ),
                    trailing: Text(
                      "${ecgc}",
                      style: TextStyle(
                        color: ((int e) {
                          if (e == 15) {
                            return Color.fromRGBO(52, 168, 83, 1.0);
                          }
                          return (e < 8)
                              ? Color.fromRGBO(234, 67, 53, 1.0)
                              : Color.fromRGBO(251, 188, 4, 1.0);
                        })(ecgc),
                        fontSize: 36,
                      ),
                    ),
                  );
                },
                backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                isExpanded: expanded[1],
                canTapOnHeader: true,
                body: (() {
                  return ECG(ecgCallback, ecg);
                })(),
              ),
              ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    title: Text(
                      "MGAP",
                      style: TextStyle(
                          color: Color.fromRGBO(44, 73, 108, 1.0),
                          fontSize: 18),
                    ),
                    trailing: Text(
                      "${mgapc}",
                      style: TextStyle(
                        color: ((int e) {
                          if (e >= 23) {
                            return Color.fromRGBO(52, 168, 83, 1.0);
                          }
                          return (e < 18)
                              ? Color.fromRGBO(234, 67, 53, 1.0)
                              : Color.fromRGBO(251, 188, 4, 1.0);
                        })(mgapc),
                        fontSize: 36,
                      ),
                    ),
                  );
                },
                backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                isExpanded: expanded[2],
                canTapOnHeader: true,
                body: (() {
                  return MGAP(mgapCallback, mgap);
                })(),
              ),
            ],
          ),
        ],
      )
    );
  }
}
