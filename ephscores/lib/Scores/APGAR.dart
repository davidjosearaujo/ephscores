import 'package:flutter/material.dart';

// ignore: must_be_immutable
class APGAR extends StatefulWidget {
  Function callback;
  List<int> values;

  APGAR(this.callback, this.values);

  @override
  _APGARState createState() => _APGARState();
}

class _APGARState extends State<APGAR> {
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
              return widget.values[0] == -1 ? null : widget.values[0];
            })(),
            hint: Text("Respiração"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Chora vigorosamente"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Lenta e irregular, fraca"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Não ventila"),
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
              return widget.values[1] == -1 ? null : widget.values[1];
            })(),
            hint: Text("Frequência cardíaca"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text(">100"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("<100"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Ausente"),
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
              return widget.values[2] == -1 ? null : widget.values[2];
            })(),
            hint: Text("Irritabilidade reflexa"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Chora, espirra ou tosse em resposta a estímulos"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Responde a estímulos"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Não responde a estímulos"),
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
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[3] == -1 ? null : widget.values[3];
            })(),
            hint: Text("Tónus muscular"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Ativo, músculos tensos e fletidos"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Alguma tensão muscular e flexão dos músculos"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Músculos moles e caídos, sem atividade"),
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
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.values[4] == -1 ? null : widget.values[4];
            })(),
            hint: Text("Cor"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 2,
                child: Text("Completamente rosado"),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Rosado com extremidades cianosadas"),
              ),
              DropdownMenuItem(
                value: 0,
                child: Text("Pálido ou cianosado"),
              ),
              DropdownMenuItem(
                value: -1,
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
      ],
    );
  }
}
