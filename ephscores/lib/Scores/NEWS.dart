import 'package:flutter/material.dart';

// ignore: must_be_immutable
class NEWS extends StatefulWidget {
  Function callback;
  List<int> indices;
  int sum;

  NEWS(this.callback, this.indices);

  @override
  _NEWSState createState() => _NEWSState();
}

class _NEWSState extends State<NEWS> {
  List<int> values = List.filled(7, 0);

  @override
  Widget build(BuildContext context) {
    widget.callback(widget.indices, values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[0],
            hint: Text("Frequência respiratória"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤8"),
                onTap: () {
                  values[0] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("9-11"),
                onTap: () {
                  values[0] = 1;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("12-20"),
                onTap: () {
                  values[0] = 0;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("21-24"),
                onTap: () {
                  values[0] = 2;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("≥25"),
                onTap: () {
                  values[0] = 3;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[0] = e;
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[1],
            hint: Text("SPO2"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤91"),
                onTap: () {
                  values[1] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("92-93"),
                onTap: () {
                  values[1] = 2;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("94-95"),
                onTap: () {
                  values[1] = 1;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("≥96"),
                onTap: () {
                  values[1] = 0;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[1] = e;
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[2],
            hint: Text("O2 Suplementar"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("Sim"),
                onTap: () {
                  values[2] = 2;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("Não"),
                onTap: () {
                  values[2] = 0;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[2] = e;
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[3],
            hint: Text("Temperatura"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤35"),
                onTap: () {
                  values[3] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("35.1-36.0"),
                onTap: () {
                  values[3] = 1;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("36.1-38.0"),
                onTap: () {
                  values[3] = 0;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("38.1-39.0"),
                onTap: () {
                  values[3] = 1;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("≥39.1"),
                onTap: () {
                  values[3] = 2;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[3] = e;
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[4],
            hint: Text("Pressão arterial sistólica"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤90"),
                onTap: () {
                  values[4] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("91-100"),
                onTap: () {
                  values[4] = 2;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("101-110"),
                onTap: () {
                  values[4] = 1;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("111-219"),
                onTap: () {
                  values[4] = 0;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("≥220"),
                onTap: () {
                  values[4] = 3;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[4] = e;
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[5],
            hint: Text("Frequência cardíaca"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("≤40"),
                onTap: () {
                  values[5] = 3;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("41-50"),
                onTap: () {
                  values[5] = 1;
                },
              ),
              DropdownMenuItem(
                value: 2,
                child: Text("51-90"),
                onTap: () {
                  values[5] = 0;
                },
              ),
              DropdownMenuItem(
                value: 3,
                child: Text("91-110"),
                onTap: () {
                  values[5] = 1;
                },
              ),
              DropdownMenuItem(
                value: 4,
                child: Text("111-130"),
                onTap: () {
                  values[5] = 2;
                },
              ),
              DropdownMenuItem(
                value: 5,
                child: Text("≥131"),
                onTap: () {
                  values[5] = 3;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[5] = e;
              });
            },
          ),
        ),
        Container(
          color: Color.fromRGBO(233, 237, 244, 1.0),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: DropdownButton(
            value: widget.indices[6],
            hint: Text("Nível de consciência"),
            iconSize: 0.0,
            style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text("a"),
                onTap: () {
                  values[6] = 0;
                },
              ),
              DropdownMenuItem(
                value: 1,
                child: Text("V, D ou S"),
                onTap: () {
                  values[6] = 3;
                },
              ),
            ],
            onChanged: (e) {
              setState(() {
                widget.indices[6] = e;
              });
            },
          ),
        ),
      ],
    );
  }
}
