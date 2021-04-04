import 'package:ephscores/Scores/Cincinnati.dart';
import 'package:ephscores/Scores/ECG.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Scores/MGAP.dart';
import 'Scores/NEWS.dart';

// ignore: must_be_immutable
class Score extends StatefulWidget {
  SharedPreferences prefs1;
  List<int> rootvals = [0, 3, 3, 0];
  List<bool> cincinnati = List<bool>.filled(3, false);
  List<int> ecg = List<int>.filled(3, 0);
  List<int> mgap = List<int>.filled(3, -1);
  List<int> news = List<int>.filled(7, null);

  @override
  _ScoreState createState() => _ScoreState();
}

class _ScoreState extends State<Score> {
  List<bool> expanded = List<bool>.filled(8, false);

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    SharedPreferences.getInstance().then((value) {
      setState(() async {

        widget.cincinnati[0] =
            value.containsKey('s1.0') ? value.getBool('s1.0') : false;
        widget.cincinnati[1] =
            value.containsKey('s1.1') ? value.getBool('s1.1') : false;
        widget.cincinnati[2] =
            value.containsKey('s1.2') ? value.getBool('s1.2') : false;

        widget.ecg[0] = value.containsKey('s2.0') ? value.getInt('s2.0') : 0;
        widget.ecg[1] = value.containsKey('s2.1') ? value.getInt('s2.1') : 0;
        widget.ecg[2] = value.containsKey('s2.2') ? value.getInt('s2.2') : 0;

        widget.mgap[0] = value.containsKey('s3.0') ? value.getInt('s3.0') : -1;
        widget.mgap[1] = value.containsKey('s3.1') ? value.getInt('s3.1') : -1;
        widget.mgap[2] = value.containsKey('s3.2') ? value.getInt('s3.2') : -1;

        widget.news[0] =
            value.containsKey('s4.0') ? value.getInt('s4.0') : null;
        widget.news[1] =
            value.containsKey('s4.1') ? value.getInt('s4.1') : null;
        widget.news[2] =
            value.containsKey('s4.2') ? value.getInt('s4.2') : null;
        widget.news[3] =
            value.containsKey('s4.3') ? value.getInt('s4.3') : null;
        widget.news[4] =
            value.containsKey('s4.4') ? value.getInt('s4.4') : null;
        widget.news[5] =
            value.containsKey('s4.5') ? value.getInt('s4.5') : null;
        widget.news[6] =
            value.containsKey('s4.6') ? value.getInt('s4.6') : null;
      });
    });
  }

  Future<bool> save() async {
    widget.prefs1 = await SharedPreferences.getInstance();
    widget.prefs1.setBool("s1.0", widget.cincinnati[0]);
    widget.prefs1.setBool("s1.1", widget.cincinnati[1]);
    widget.prefs1.setBool("s1.2", widget.cincinnati[2]);
    widget.prefs1.setInt("s1.r", widget.rootvals[0]);
    widget.prefs1.setInt('s2.0', widget.ecg[0]);
    widget.prefs1.setInt('s2.1', widget.ecg[1]);
    widget.prefs1.setInt('s2.2', widget.ecg[2]);
    widget.prefs1.setInt("s2.r", widget.rootvals[1]);
    widget.prefs1.setInt('s3.0', widget.mgap[0]);
    widget.prefs1.setInt('s3.1', widget.mgap[1]);
    widget.prefs1.setInt('s3.2', widget.mgap[2]);
    widget.prefs1.setInt("s3.r", widget.rootvals[2]);
    widget.prefs1.setInt("s4.r", widget.rootvals[3]);
    return true;
  }

  void reset() {
    widget.cincinnati = List<bool>.filled(3, false);
    widget.ecg = List<int>.filled(3, 0);
    widget.mgap = List<int>.filled(3, -1);
    widget.news = List<int>.filled(7, null);
    widget.rootvals = [0, 3, 3, 0];
  }

  Future<void> cincinattiCallback(List<bool> i) async {
    setState(() {
      widget.rootvals[0] = 0;
      for (bool x in i) {
        if (x) widget.rootvals[0]++;
      }
      widget.cincinnati = i;
    });
  }

  Future<void> ecgCallback(List<int> i) async {
    setState(() {
      if (i[0] == 0 && i[1] == 0 && i[2] == 0) {
        widget.rootvals[1] = 3;
      } else {
        widget.rootvals[1] = i[0] + i[1] + i[2];
      }
      widget.ecg = i;
    });
  }

  Future<void> mgapCallback(List<int> i) async {
    setState(() {
      widget.rootvals[2] = widget.rootvals[1];
      for (int x in i) {
        if (x != -1) widget.rootvals[2] += x;
      }
      widget.mgap = i;
    });
  }

  Future<void> newsCallback(List<int> i, List<int> v) async {
    widget.prefs1 = await SharedPreferences.getInstance();
    setState(() {
      bool clean = true;
      for (int c in i) {
        if (c != null) {
          clean = false;
          widget.prefs1.setInt("s4." + i.toString(), c);
        }
      }
      if (clean) {
        widget.rootvals[3] = 0;
      } else {
        widget.rootvals[3] = 0;
        for (int c in v) {
          widget.rootvals[3] += c;
        }
      }
      widget.news = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return save();
      },
      child: Scaffold(
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
                  setState(() {
                    widget.prefs1.clear();
                    reset();
                  });
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
                          "${widget.rootvals[0]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 0) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e > 2)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[0]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[0],
                    canTapOnHeader: true,
                    body: (() {
                      return Cincinnati(cincinattiCallback, widget.cincinnati);
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
                          "${widget.rootvals[1]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 15) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e < 8)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[1]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[1],
                    canTapOnHeader: true,
                    body: (() {
                      return ECG(ecgCallback, widget.ecg);
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
                          "${widget.rootvals[2]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e >= 23) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e < 18)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[2]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[2],
                    canTapOnHeader: true,
                    body: (() {
                      return MGAP(mgapCallback, widget.mgap);
                    })(),
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          "NEWS",
                          style: TextStyle(
                              color: Color.fromRGBO(44, 73, 108, 1.0),
                              fontSize: 18),
                        ),
                        trailing: Text(
                          "${widget.rootvals[3]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e <= 4 && e != 3) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e >= 7)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[3]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[3],
                    canTapOnHeader: true,
                    body: (() {
                      return NEWS(newsCallback, widget.news);
                    })(),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
