import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Score extends StatefulWidget {
  int s1, s2, s3, s4, s5, s6, s7, s8;
  SharedPreferences prefs1;

  Score({
    this.s1 = 0,
    this.s2 = 3,
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
  List<bool> cincinnati = [false, false, false];
  int ecgvisual = 1, ecgverbal = 1, ecgmove = 1;

  @override
  void initState() {
    super.initState();
  }

  void ecgcount() {
    widget.s2 = ecgverbal + ecgvisual + ecgmove;
  }

  void refresh() async {
    widget.prefs1 = await SharedPreferences.getInstance();
    widget.prefs1.setInt('s1', widget.s1);
    widget.prefs1.setInt('s2', widget.s2);
    widget.prefs1.setInt('s3', widget.s3);
    widget.prefs1.setInt('s4', widget.s4);
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
              onPressed: () {

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
                        "${widget.s1}",
                        style: TextStyle(
                          color: ((int e) {
                            if (e == 0) {
                              return Color.fromRGBO(52, 168, 83, 1.0);
                            }
                            return (e > 2)
                                ? Color.fromRGBO(234, 67, 53, 1.0)
                                : Color.fromRGBO(251, 188, 4, 1.0);
                          })(widget.s1),
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
                              e ? widget.s1++ : widget.s1--;
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
                              e ? widget.s1++ : widget.s1--;
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
                              e ? widget.s1++ : widget.s1--;
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
                        "${widget.s2}",
                        style: TextStyle(
                          color: ((int e) {
                            if (e == 15) {
                              return Color.fromRGBO(52, 168, 83, 1.0);
                            }
                            return (e < 8)
                                ? Color.fromRGBO(234, 67, 53, 1.0)
                                : Color.fromRGBO(251, 188, 4, 1.0);
                          })(widget.s2),
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
                          value: ecgvisual,
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
                              ecgvisual = e;
                              ecgcount();
                            });
                          },
                        ),
                      ),
                      Container(
                        color: Color.fromRGBO(233, 237, 244, 1.0),
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: DropdownButton(
                          value: ecgverbal,
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
                              ecgverbal = e;
                              ecgcount();
                            });
                          },
                        ),
                      ),
                      Container(
                        color: Color.fromRGBO(233, 237, 244, 1.0),
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: DropdownButton(
                          value: ecgmove,
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
                              ecgmove = e;
                              ecgcount();
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
        ));
  }
}
