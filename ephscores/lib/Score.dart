import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Score extends StatefulWidget {
  int s1, s2, s3, s4, s5, s6, s7, s8;
  SharedPreferences prefs1;

  Score({
    this.s3 = 0,
    this.s4 = 0,
    this.s5 = 0,
    this.s6 = 0,
    this.s7 = 0,
    this.s8 = 0,
  });

  @override
  _ScoreState createState() => _ScoreState();
}

class _ScoreState extends State<Score> {
  List<bool> expanded = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];
  List<bool> cincinnati = List<bool>.filled(3, false);
  List<int> ecg = List<int>.filled(3, 0);
  List<int> mgap = List<int>.filled(3, -1);

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

  Future<bool> save() async {
    widget.prefs1 = await SharedPreferences.getInstance();
    widget.prefs1.setBool("s1.0", cincinnati[0]);
    widget.prefs1.setBool("s1.1", cincinnati[1]);
    widget.prefs1.setBool("s1.2", cincinnati[2]);
    widget.prefs1.setInt('s2.0', ecg[0]);
    widget.prefs1.setInt('s2.1', ecg[1]);
    widget.prefs1.setInt('s2.2', ecg[2]);
    widget.prefs1.setInt('s3.0', mgap[0]);
    widget.prefs1.setInt('s3.1', mgap[1]);
    widget.prefs1.setInt('s3.2', mgap[2]);
    setState(() {});
    return true;
  }

  int cincinattiCount() {
    int c = 0;
    for (bool x in cincinnati) {
      if (x) c++;
    }
    return c;
  }

  int ecgCount() {
    if (ecg[0] == 0 && ecg[1] == 0 && ecg[2] == 0) {
      return 3;
    } else {
      return ecg[0] + ecg[1] + ecg[2];
    }
  }

  int mgapCount() {
    int c = ecgCount();
    for (int x in mgap) {
      if (x != -1) c += x;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: save,
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
                          "${cincinattiCount()}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 0) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e > 2)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(cincinattiCount()),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[0],
                    canTapOnHeader: true,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          tileColor: Color.fromRGBO(233, 237, 244, 1.0),
                          title: Text(
                            "Paresia facial",
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 16),
                          ),
                          trailing: Checkbox(
                            value: cincinnati[0],
                            onChanged: (e) {
                              setState(() {
                                cincinnati[0] = e;
                                cincinattiCount();
                              });
                            },
                          ),
                        ),
                        ListTile(
                          tileColor: Color.fromRGBO(233, 237, 244, 1.0),
                          title: Text(
                            "Queda do membro superior",
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 16),
                          ),
                          trailing: Checkbox(
                            value: cincinnati[1],
                            onChanged: (e) {
                              setState(() {
                                cincinnati[1] = e;
                                cincinattiCount();
                              });
                            },
                          ),
                        ),
                        ListTile(
                          tileColor: Color.fromRGBO(233, 237, 244, 1.0),
                          title: Text(
                            "Alteração na fala",
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 16),
                          ),
                          trailing: Checkbox(
                            value: cincinnati[2],
                            onChanged: (e) {
                              setState(() {
                                cincinnati[2] = e;
                                cincinattiCount();
                              });
                            },
                          ),
                        )
                      ],
                    ),
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
                          "${ecgCount()}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e == 15) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e < 8)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(ecgCount()),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[1],
                    canTapOnHeader: true,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: DropdownButton(
                            value: (() {
                              return ecg[0] == 0 ? null : ecg[0];
                            })(),
                            hint: Text("Resposta Visual"),
                            iconSize: 0.0,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text("Sem resposta"),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text("Resposta á dor"),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text("Resposta á fala"),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text("Espontaneo"),
                              )
                            ],
                            onChanged: (e) {
                              setState(() {
                                ecg[0] = e;
                                ecgCount();
                              });
                            },
                          ),
                        ),
                        Container(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: DropdownButton(
                            value: (() {
                              return ecg[1] == 0 ? null : ecg[1];
                            })(),
                            hint: Text("Resposta Verbal"),
                            iconSize: 0.0,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text("Sem resposta"),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text("Sons incompreensiveis"),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text("Palavras inapropriadas"),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text("Confuso"),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text("Orientado no tempo e espaço"),
                              )
                            ],
                            onChanged: (e) {
                              setState(() {
                                ecg[1] = e;
                                ecgCount();
                              });
                            },
                          ),
                        ),
                        Container(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: DropdownButton(
                            value: (() {
                              return ecg[2] == 0 ? null : ecg[2];
                            })(),
                            hint: Text("Resposta Motora"),
                            iconSize: 0.0,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text("Sem resposta"),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text("Extensão anormal"),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text("Flexão anormal"),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text("Flexão normal"),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text("Localiza dor"),
                              ),
                              DropdownMenuItem(
                                value: 6,
                                child: Text("Ao comando"),
                              )
                            ],
                            onChanged: (e) {
                              setState(() {
                                ecg[2] = e;
                                ecgCount();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
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
                          "${mgapCount()}",
                          style: TextStyle(
                            color: ((int e) {
                              if (e >= 23) {
                                return Color.fromRGBO(52, 168, 83, 1.0);
                              }
                              return (e < 18)
                                  ? Color.fromRGBO(234, 67, 53, 1.0)
                                  : Color.fromRGBO(251, 188, 4, 1.0);
                            })(mgapCount()),
                            fontSize: 36,
                          ),
                        ),
                      );
                    },
                    backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
                    isExpanded: expanded[2],
                    canTapOnHeader: true,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: DropdownButton(
                            value: (() {
                              return mgap[0] == -1 ? null : mgap[0];
                            })(),
                            hint: Text("Mecanismo lesão"),
                            iconSize: 0.0,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text("Penetrante"),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text("Fechado"),
                              ),
                            ],
                            onChanged: (e) {
                              setState(() {
                                mgap[0] = e;
                                mgapCount();
                              });
                            },
                          ),
                        ),
                        Container(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: DropdownButton(
                            value: (() {
                              return mgap[1] == -1 ? null : mgap[1];
                            })(),
                            hint: Text("Idade"),
                            iconSize: 0.0,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text(">60"),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text("<60"),
                              ),
                            ],
                            onChanged: (e) {
                              setState(() {
                                mgap[1] = e;
                                mgapCount();
                              });
                            },
                          ),
                        ),
                        Container(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: DropdownButton(
                            value: (() {
                              return mgap[2] == -1 ? null : mgap[2];
                            })(),
                            hint: Text("PAS(mmHg)"),
                            iconSize: 0.0,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text("<60"),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text("60-123"),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text(">120"),
                              ),
                            ],
                            onChanged: (e) {
                              setState(() {
                                mgap[2] = e;
                                mgapCount();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
