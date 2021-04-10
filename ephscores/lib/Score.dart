import 'package:ephscores/Scores/Cincinnati.dart';
import 'package:ephscores/Scores/ECG.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Scores/MGAP.dart';
import 'Scores/NEWS.dart';
import 'Scores/PROACS.dart';
import 'Scores/RACE.dart';
import 'Scores/RTS.dart';
import 'Scores/TAP.dart';

// ignore: must_be_immutable
class Score extends StatefulWidget {
  SharedPreferences prefs1;
  List<int> rootvals = [0, 3, 3, 0, 0, 0, 0, 0];
  bool dir = false;
  List<bool> cincinnati = List<bool>.filled(3, false);
  List<int> ecg = List<int>.filled(3, 0);
  List<int> mgap = List<int>.filled(3, -1);
  List<int> news = List<int>.filled(7, -1);
  List<int> newsv = List<int>.filled(7, 0);
  List<int> proacs = List<int>.filled(4, -1);
  List<int> tap = List<int>.filled(3, -1);
  List<int> race = List<int>.filled(6, -1);
  List<int> rts = List<int>.filled(2, -1);

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
      setState(() {
        widget.rootvals[0] = value.containsKey("s1.r") ? value.get("s1.r") : 0;
        widget.rootvals[1] = value.containsKey("s2.r") ? value.get("s2.r") : 3;
        widget.rootvals[2] = value.containsKey("s3.r") ? value.get("s3.r") : 3;
        widget.rootvals[3] = value.containsKey("s4.r") ? value.get("s4.r") : 0;
        widget.rootvals[4] = value.containsKey("s5.r") ? value.get("s5.r") : 0;
        widget.rootvals[5] = value.containsKey("s6.r") ? value.get("s6.r") : 0;
        widget.rootvals[6] = value.containsKey("s7.r") ? value.get("s7.r") : 0;
        widget.rootvals[7] = value.containsKey("s8.r") ? value.get("s8.r") : 0;

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

        widget.news[0] = value.containsKey('s4.0') ? value.getInt('s4.0') : -1;
        widget.news[1] = value.containsKey('s4.1') ? value.getInt('s4.1') : -1;
        widget.news[2] = value.containsKey('s4.2') ? value.getInt('s4.2') : -1;
        widget.news[3] = value.containsKey('s4.3') ? value.getInt('s4.3') : -1;
        widget.news[4] = value.containsKey('s4.4') ? value.getInt('s4.4') : -1;
        widget.news[5] = value.containsKey('s4.5') ? value.getInt('s4.5') : -1;
        widget.news[6] = value.containsKey('s4.6') ? value.getInt('s4.6') : -1;

        widget.proacs[0] =
            value.containsKey('s5.0') ? value.getInt('s5.0') : -1;
        widget.proacs[1] =
            value.containsKey('s5.1') ? value.getInt('s5.1') : -1;
        widget.proacs[2] =
            value.containsKey('s5.2') ? value.getInt('s5.2') : -1;
        widget.proacs[3] =
            value.containsKey('s5.3') ? value.getInt('s5.3') : -1;

        widget.tap[0] = value.containsKey('s6.0') ? value.getInt('s6.0') : -1;
        widget.tap[1] = value.containsKey('s6.1') ? value.getInt('s6.1') : -1;
        widget.tap[2] = value.containsKey('s6.2') ? value.getInt('s6.2') : -1;

        widget.dir = value.containsKey('s7.d') ? value.getBool('s7.d') : false;
        widget.race[0] = value.containsKey('s7.0') ? value.getInt('s7.0') : -1;
        widget.race[1] = value.containsKey('s7.1') ? value.getInt('s7.1') : -1;
        widget.race[2] = value.containsKey('s7.2') ? value.getInt('s7.2') : -1;
        widget.race[3] = value.containsKey('s7.3') ? value.getInt('s7.3') : -1;
        widget.race[4] = value.containsKey('s7.4') ? value.getInt('s7.4') : -1;
        widget.race[5] = value.containsKey('s7.5') ? value.getInt('s7.5') : -1;

        widget.rts[0] = value.containsKey('s8.0') ? value.getInt('s8.0') : -1;
        widget.rts[1] = value.containsKey('s8.1') ? value.getInt('s8.1') : -1;
      });
    });
  }

  Future<bool> save() async {
    widget.prefs1 = await SharedPreferences.getInstance();
    // Cincinnati
    widget.prefs1.setBool("s1.0", widget.cincinnati[0]);
    widget.prefs1.setBool("s1.1", widget.cincinnati[1]);
    widget.prefs1.setBool("s1.2", widget.cincinnati[2]);
    // Glasgow
    widget.prefs1.setInt('s2.0', widget.ecg[0]);
    widget.prefs1.setInt('s2.1', widget.ecg[1]);
    widget.prefs1.setInt('s2.2', widget.ecg[2]);
    // NEWS
    widget.prefs1.setInt("s4.0", widget.news[0]);
    widget.prefs1.setInt("s4.1", widget.news[1]);
    widget.prefs1.setInt("s4.2", widget.news[2]);
    widget.prefs1.setInt("s4.3", widget.news[3]);
    widget.prefs1.setInt("s4.4", widget.news[4]);
    widget.prefs1.setInt("s4.5", widget.news[5]);
    widget.prefs1.setInt("s4.6", widget.news[6]);
    // MGAP
    widget.prefs1.setInt('s3.0', widget.mgap[0]);
    widget.prefs1.setInt('s3.1', widget.mgap[1]);
    widget.prefs1.setInt('s3.2', widget.mgap[2]);
    // PROACS
    widget.prefs1.setInt('s5.0', widget.proacs[0]);
    widget.prefs1.setInt('s5.1', widget.proacs[1]);
    widget.prefs1.setInt('s5.2', widget.proacs[2]);
    widget.prefs1.setInt('s5.3', widget.proacs[3]);
    // TAP
    widget.prefs1.setInt('s6.0', widget.tap[0]);
    widget.prefs1.setInt('s6.1', widget.tap[1]);
    widget.prefs1.setInt('s6.2', widget.tap[2]);
    // RACE
    widget.prefs1.setBool('s7.d', widget.dir);
    widget.prefs1.setInt('s7.0', widget.race[0]);
    widget.prefs1.setInt('s7.1', widget.race[1]);
    widget.prefs1.setInt('s7.2', widget.race[2]);
    widget.prefs1.setInt('s7.3', widget.race[3]);
    widget.prefs1.setInt('s7.4', widget.race[4]);
    widget.prefs1.setInt('s7.5', widget.race[5]);
    // RTS
    widget.prefs1.setInt('s8.0', widget.rts[0]);
    widget.prefs1.setInt('s8.1', widget.rts[1]);
    // Display values
    widget.prefs1.setInt("s1.r", widget.rootvals[0]);
    widget.prefs1.setInt("s2.r", widget.rootvals[1]);
    widget.prefs1.setInt("s3.r", widget.rootvals[2]);
    widget.prefs1.setInt("s4.r", widget.rootvals[3]);
    widget.prefs1.setInt("s5.r", widget.rootvals[4]);
    widget.prefs1.setInt("s6.r", widget.rootvals[5]);
    widget.prefs1.setInt("s7.r", widget.rootvals[6]);
    widget.prefs1.setInt("s8.r", widget.rootvals[7]);
    return true;
  }

  void reset() {
    widget.dir = false;
    widget.cincinnati = List<bool>.filled(3, false);
    widget.ecg = List<int>.filled(3, 0);
    widget.mgap = List<int>.filled(3, -1);
    widget.news = List<int>.filled(7, -1);
    widget.newsv = List<int>.filled(7, 0);
    widget.proacs = List<int>.filled(4, -1);
    widget.tap = List<int>.filled(3, -1);
    widget.race = List<int>.filled(6, -1);
    widget.rts = List<int>.filled(2, -1);
    widget.rootvals = [0, 3, 3, 0, 0, 0, 0, 0];
  }

  void cincinattiCallback(List<bool> i) {
    setState(() {
      widget.rootvals[0] = 0;
      for (bool x in i) {
        if (x) widget.rootvals[0]++;
      }
      widget.cincinnati = i;
    });
  }

  void ecgCallback(List<int> i) {
    setState(() {
      if (i[0] >= 1 && i[1] >= 1 && i[2] >= 1) {
        widget.rootvals[7] -= ECGtoRTS(widget.rootvals[1]);
        widget.rootvals[2] -= widget.rootvals[1];
        widget.rootvals[1] = i[0] + i[1] + i[2];
        widget.rootvals[2] += widget.rootvals[1];
        widget.rootvals[7] += ECGtoRTS(widget.rootvals[1]);
      } else {
        widget.rootvals[1] = 3;
      }
      widget.ecg = i;
    });
  }

  void mgapCallback(List<int> i) {
    widget.rootvals[2] = widget.rootvals[1];
    setState(() {
      for (int x in i) {
        if (x != -1) widget.rootvals[2] += x;
      }
      widget.mgap = i;
    });
  }

  void newsCallback(List<int> i, List<int> v) {
    setState(() {
      widget.rootvals[3] = 0;
      for (int x in v) {
        if (x != -1) widget.rootvals[3] += x;
      }
      widget.news = i;
    });
  }

  void proacsCallback(List<int> i) {
    setState(() {
      widget.rootvals[4] = 0;
      for (int x in i) {
        if (x != -1) widget.rootvals[4] += x;
      }
      widget.proacs = i;
    });
  }

  void tapCallback(List<int> i) {
    setState(() {
      widget.rootvals[5] = 0;
      for (int x in i) {
        if (x != -1) widget.rootvals[5]++;
      }
      widget.tap = i;
    });
  }

  void raceCallback(List<int> x, bool d) {
    setState(() {
      widget.rootvals[6] = 0;
      for (int i = 0; i < x.length; i++) {
        if (x[i] != -1 && i > 0) widget.rootvals[6] += x[i];
      }
      widget.race = x;
      widget.dir = d;
    });
  }

  void rtsCallback(List<int> i) {
    widget.rootvals[7] = ECGtoRTS(widget.rootvals[1]);
    setState(() {
      for (int x in i) {
        if (x != -1) widget.rootvals[7] += x;
      }
      widget.rts = i;
    });
  }

  int ECGtoRTS(ecg) {
    int rts = 0;
    if (ecg == 3) {
      rts = 0;
    } else if (ecg <= 5) {
      rts = 1;
    } else if (ecg <= 8) {
      rts = 2;
    } else if (ecg <= 12) {
      rts = 3;
    } else {
      rts = 4;
    }
    return rts;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return save();
      },
      child: Scaffold(
          backgroundColor: Color.fromRGBO(233, 237, 244, 1.0),
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
                    expanded = List<bool>.filled(8, false);
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
                      return NEWS(newsCallback, widget.news, widget.newsv);
                    })(),
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          "PROACS",
                          style: TextStyle(
                              color: Color.fromRGBO(44, 73, 108, 1.0),
                              fontSize: 18),
                        ),
                        trailing: Text(
                          "${widget.rootvals[4]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 0) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e >= 3)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[4]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[4],
                    canTapOnHeader: true,
                    body: (() {
                      return PROACS(proacsCallback, widget.proacs);
                    })(),
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          "TAP",
                          style: TextStyle(
                              color: Color.fromRGBO(44, 73, 108, 1.0),
                              fontSize: 18),
                        ),
                        trailing: Text(
                          "${widget.rootvals[5]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 0) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e >= 3)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[5]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[5],
                    canTapOnHeader: true,
                    body: (() {
                      return TAP(tapCallback, widget.tap);
                    })(),
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          "RACE",
                          style: TextStyle(
                              color: Color.fromRGBO(44, 73, 108, 1.0),
                              fontSize: 18),
                        ),
                        trailing: Text(
                          "${widget.rootvals[6]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 0) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e >= 5)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[6]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[6],
                    canTapOnHeader: true,
                    body: (() {
                      return RACE(raceCallback, widget.race, widget.dir);
                    })(),
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          "RTS",
                          style: TextStyle(
                              color: Color.fromRGBO(44, 73, 108, 1.0),
                              fontSize: 18),
                        ),
                        trailing: Text(
                          "${widget.rootvals[7]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 16) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e <= 10)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[7]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[7],
                    canTapOnHeader: true,
                    body: (() {
                      return RTS(rtsCallback, widget.rts);
                    })(),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
