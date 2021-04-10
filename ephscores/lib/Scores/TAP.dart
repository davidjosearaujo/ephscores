import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TAP extends StatefulWidget {
  Function callback;
  List<int> values;

  TAP(this.callback, this.values);

  @override
  _TAPState createState() => _TAPState();
}

class _TAPState extends State<TAP> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[0] == -1 ? null : widget.values[0];
            })(),
            hint: Text("Aparência"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("Tonús muscular anormal"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Não interage"),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("Difícil de consolar"),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("Olhar anormal"),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("Choro / Discurso anormal"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.values[0] = e;
                widget.callback(widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[1] == -1 ? null : widget.values[1];
            })(),
            hint: Text("Esforço respiratório"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("Sons anormais"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Posição tripé / anormal"),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("Tiragem"),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("Adejo nasal"),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("Apneia / Gasping"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.values[1] = e;
                widget.callback(widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[2] == -1 ? null : widget.values[2];
            })(),
            hint: Text("Circulação"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("Pele pálida"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Pele marmoreada"),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("Cianose"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.values[2] = e;
                widget.callback(widget.values);
              });
            },
          ),
        ),
      ],
    );
  }
}
