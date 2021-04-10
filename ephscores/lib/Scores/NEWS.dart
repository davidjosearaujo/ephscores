import 'package:flutter/material.dart';

// ignore: must_be_immutable
class NEWS extends StatefulWidget {
  Function callback;
  List<int> indices;
  List<int> values;
  int sum;

  NEWS(this.callback, this.indices, this.values);

  @override
  _NEWSState createState() => _NEWSState();
}

class _NEWSState extends State<NEWS> {
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
              return widget.indices[0] == -1 ? null : widget.indices[0];
            })(),
            hint: Text("Frequência respiratória"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤8"),
                onTap: () {
                  widget.values[0] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("9-11"),
                onTap: () {
                  widget.values[0] = 1;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("12-20"),
                onTap: () {
                  widget.values[0] = 0;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("21-24"),
                onTap: () {
                  widget.values[0] = 2;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("≥25"),
                onTap: () {
                  widget.values[0] = 3;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[0] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.indices[1] == -1 ? null : widget.indices[1];
            })(),
            hint: Text("SPO2"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤91"),
                onTap: () {
                  widget.values[1] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("92-93"),
                onTap: () {
                  widget.values[1] = 2;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("94-95"),
                onTap: () {
                  widget.values[1] = 1;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("≥96"),
                onTap: () {
                  widget.values[1] = 0;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[1] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.indices[2] == -1 ? null : widget.indices[2];
            })(),
            hint: Text("O2 Suplementar"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("Sim"),
                onTap: () {
                  widget.values[2] = 2;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Não"),
                onTap: () {
                  widget.values[2] = 0;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[2] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.indices[3] == -1 ? null : widget.indices[3];
            })(),
            hint: Text("Temperatura"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤35"),
                onTap: () {
                  widget.values[3] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("35.1-36.0"),
                onTap: () {
                  widget.values[3] = 1;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("36.1-38.0"),
                onTap: () {
                  widget.values[3] = 0;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("38.1-39.0"),
                onTap: () {
                  widget.values[3] = 1;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("≥39.1"),
                onTap: () {
                  widget.values[3] = 2;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[3] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.indices[4] == -1 ? null : widget.indices[4];
            })(),
            hint: Text("Pressão arterial sistólica"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤90"),
                onTap: () {
                  widget.values[4] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("91-100"),
                onTap: () {
                  widget.values[4] = 2;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("101-110"),
                onTap: () {
                  widget.values[4] = 1;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("111-219"),
                onTap: () {
                  widget.values[4] = 0;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("≥220"),
                onTap: () {
                  widget.values[4] = 3;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[4] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.indices[5] == -1 ? null : widget.indices[5];
            })(),
            hint: Text("Frequência cardíaca"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤40"),
                onTap: () {
                  widget.values[5] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("41-50"),
                onTap: () {
                  widget.values[5] = 1;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("51-90"),
                onTap: () {
                  widget.values[5] = 0;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("91-110"),
                onTap: () {
                  widget.values[5] = 1;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("111-130"),
                onTap: () {
                  widget.values[5] = 2;
                },
              ),
              DropdownMenuItem(
                value: 5,
                child: Text("≥131"),
                onTap: () {
                  widget.values[5] = 3;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[5] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: (() {
              return widget.indices[6] == -1 ? null : widget.indices[6];
            })(),
            hint: Text("Nível de consciência"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("A"),
                onTap: () {
                  widget.values[6] = 0;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("V, D ou S"),
                onTap: () {
                  widget.values[6] = 3;
                },
              ),
              DropdownMenuItem(
                value: -1,
                child: Text("Nenhum"),
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[6] = e;
                widget.callback(widget.indices, widget.values);
              });
            },
          ),
        ),
      ],
    );
  }
}
