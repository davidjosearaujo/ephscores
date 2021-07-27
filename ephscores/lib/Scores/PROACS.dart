
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class PROACS extends StatefulWidget {
  Function callback;
  List<int> values;

  PROACS(this.callback, this.values);

  @override
  _PROACSState createState() => _PROACSState();
}

class _PROACSState extends State<PROACS> {
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
            hint: Text("Idade"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("<72"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("≥72"),
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
            hint: Text("TAS(mmHg)"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≥116"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("<116"),
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
            hint: Text("Classe de Killip"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("1"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("2 ou 3"),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("4"),
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
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[3] == -1 ? null : widget.values[3];
            })(),
            hint: Text("Elevação de ST"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("Não"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Sim"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.values[3] = e;
                widget.callback(widget.values);
              });
            },
          ),
        ),
      ],
    );
  }
}