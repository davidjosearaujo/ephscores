import 'package:flutter/material.dart';

// ignore: must_be_immutable
class RTS extends StatefulWidget {
  Function callback;
  List<int> values;

  RTS(this.callback, this.values);

  @override
  _RTSState createState() => _RTSState();
}

class _RTSState extends State<RTS> {
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
            hint: Text("Frequência respiratoria (cpm)"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("0"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("1 a 5"),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("6 a 9"),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text(">29"),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("10 a 29"),
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
            hint: Text("PAS (mmHg)"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("0"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("1 a 49"),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("50 a 75"),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("76 a 89"),
              ),
              DropdownMenuItem(
                value: 4,
                child: Text(">89"),
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
      ],
    );
  }
}
