import 'package:flutter/material.dart';

// ignore: must_be_immutable
class PTS extends StatefulWidget {
  Function callback;
  List<int> values;

  PTS(this.callback, this.values);

  @override
  _PTSState createState() => _PTSState();
}

class _PTSState extends State<PTS> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[0] == 0 ? null : widget.values[0];
            })(),
            hint: Text("Peso"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text(">20 kg"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("10-20kg"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("<10 kg"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("<10 kg"),
              ),
              DropdownMenuItem(
                value: 0,
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
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[1] == 0 ? null : widget.values[1];
            })(),
            hint: Text("Via aérea"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Normal"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Estabilizável"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Não estabilizável"),
              ),
              DropdownMenuItem(
                value: 0,
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
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[2] == 0 ? null : widget.values[2];
            })(),
            hint: Text("Pressão arterial sistólica"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text(">90 mmHg (ou pulso periférico)"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("50-90 mmHg (ou pulso fémural)"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("<50 mmHg (ou sem pulso pálpavel)"),
              ),
              DropdownMenuItem(
                value: 0,
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
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[3] == 0 ? null : widget.values[3];
            })(),
            hint: Text("Nivel de Consciência"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Acordado"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Lentificado"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Inconsciente"),
              ),
              DropdownMenuItem(
                value: 0,
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
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[4] == 0 ? null : widget.values[4];
            })(),
            hint: Text("Traumatismos"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Ausentes"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Fratura fechada"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Fratura(s) aberta/múltiplas"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.values[4] = e;
                widget.callback(widget.values);
              });
            },
          ),
        ),
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[5] == 0 ? null : widget.values[5];
            })(),
            hint: Text("Feridas"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Ausentes"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Superficiais"),
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Profundas/Penetrantes"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.values[5] = e;
                widget.callback(widget.values);
              });
            },
          ),
        ),
      ],
    );
  }
}
