import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Scores/TAP.dart';
import 'Scores/PTS.dart';

// ignore: must_be_immutable
class PediatricScore extends StatefulWidget {
  SharedPreferences prefs1;
  List<int> rootvals = [0, 12];
  List<int> tap = List<int>.filled(3, -1);
  List<int> pts = List<int>.filled(6, 0);

  @override
  _PediatricScoreState createState() => _PediatricScoreState();
}

class _PediatricScoreState extends State<PediatricScore> {
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
        widget.rootvals[1] = value.containsKey("s2.r") ? value.get("s2.r") : 0;

        widget.tap[0] = value.containsKey('s1.0') ? value.getInt('s1.0') : -1;
        widget.tap[1] = value.containsKey('s1.1') ? value.getInt('s1.1') : -1;
        widget.tap[2] = value.containsKey('s1.2') ? value.getInt('s1.2') : -1;

        widget.pts[0] = value.containsKey('s2.0') ? value.getInt('s2.0') : 0;
        widget.pts[1] = value.containsKey('s2.1') ? value.getInt('s2.1') : 0;
        widget.pts[2] = value.containsKey('s2.2') ? value.getInt('s2.2') : 0;
        widget.pts[3] = value.containsKey('s2.3') ? value.getInt('s2.3') : 0;
        widget.pts[4] = value.containsKey('s2.4') ? value.getInt('s2.4') : 0;
        widget.pts[5] = value.containsKey('s2.5') ? value.getInt('s2.5') : 0;
      });
    });
  }

  Future<bool> save() async {
    widget.prefs1 = await SharedPreferences.getInstance();
    // TAP
    widget.prefs1.setInt('s1.0', widget.tap[0]);
    widget.prefs1.setInt('s1.1', widget.tap[1]);
    widget.prefs1.setInt('s1.2', widget.tap[2]);
    // PTS
    widget.prefs1.setInt('s2.0', widget.pts[0]);
    widget.prefs1.setInt('s2.1', widget.pts[1]);
    widget.prefs1.setInt('s2.2', widget.pts[2]);
    widget.prefs1.setInt('s2.3', widget.pts[3]);
    widget.prefs1.setInt('s2.4', widget.pts[4]);
    widget.prefs1.setInt('s2.5', widget.pts[5]);
    // Display values
    widget.prefs1.setInt("s1.r", widget.rootvals[0]);
    widget.prefs1.setInt("s2.r", widget.rootvals[1]);
    return true;
  }

  void reset() {
    widget.tap = List<int>.filled(3, -1);
    widget.pts = List<int>.filled(6, 0);
    widget.rootvals = [0, 0];
  }

  void tapCallback(List<int> i) {
    setState(() {
      widget.rootvals[0] = 0;
      for (int x in i) {
        if (x != -1) widget.rootvals[0]++;
      }
      widget.tap = i;
    });
  }

  void ptsCallback(List<int> i) {
    setState(() {
      widget.rootvals[1] = 0;
      for (int x in i) {
        widget.rootvals[1] += x;
      }
      widget.pts = i;
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
            backgroundColor: Colors.white,
            foregroundColor: Color.fromRGBO(44, 73, 108, 1.0),
            shadowColor: Colors.transparent,
            title: Text(
              "Avaliação Pediátrica",
              style: TextStyle(
                  fontSize: 24, color: Color.fromRGBO(44, 73, 108, 1.0)),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Color.fromRGBO(44, 73, 108, 1.0),
                ),
                onPressed: () async {
                  widget.prefs1 = await SharedPreferences.getInstance();
                  setState(() {
                    expanded = List<bool>.filled(2, false);
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
                        tileColor: Colors.white,
                        title: Text(
                          "TAP",
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
                              return (e >= 3)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(widget.rootvals[0]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    isExpanded: expanded[0],
                    canTapOnHeader: true,
                    body: (() {
                      return TAP(tapCallback, widget.tap);
                    })(),
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        tileColor: Colors.white,
                        title: Text(
                          "PTS",
                          style: TextStyle(
                              color: Color.fromRGBO(44, 73, 108, 1.0),
                              fontSize: 18),
                        ),
                        trailing: Text(
                          "${widget.rootvals[1]}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e > 8) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              } else if (e >= 1) {
                                return Color.fromRGBO(251, 188, 4, 1.0);
                              } else {
                                return Color.fromRGBO(234, 67, 53, 1.0);
                              }
                            })(widget.rootvals[1]),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    isExpanded: expanded[1],
                    canTapOnHeader: true,
                    body: (() {
                      return PTS(ptsCallback, widget.pts);
                    })(),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
