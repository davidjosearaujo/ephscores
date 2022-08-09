import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ECG extends StatefulWidget {
  Function callback;
  List<int> values;

  ECG(this.callback, this.values);

  @override
  _ECGState createState() => _ECGState();
}

class _ECGState extends State<ECG> {
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
            hint: Text("Resposta Visual"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
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
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[1] == 0 ? null : widget.values[1];
            })(),
            hint: Text("Resposta Verbal"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
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
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[2] == 0 ? null : widget.values[2];
            })(),
            hint: Text("Resposta Motora"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
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
