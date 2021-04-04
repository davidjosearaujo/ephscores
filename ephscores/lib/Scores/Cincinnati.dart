import 'package:flutter/material.dart';

class Cincinnati extends StatefulWidget {
  Function callback;
  List<bool> values;

  Cincinnati(this.callback, this.values);

  @override
  _CincinnatiState createState() => _CincinnatiState();
}

class _CincinnatiState extends State<Cincinnati> {
  @override
  Widget build(BuildContext context) {
    widget.callback(widget.values);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          tileColor: Color.fromRGBO(233, 237, 244, 1.0),
          title: Text(
            "Paresia facial",
            style: TextStyle(
                color: Color.fromRGBO(44, 73, 108, 1.0), fontSize: 16),
          ),
          trailing: Checkbox(
            value: widget.values[0],
            onChanged: (e) {
              widget.values[0] = e;
              widget.callback(widget.values);
            },
          ),
        ),
        ListTile(
          tileColor: Color.fromRGBO(233, 237, 244, 1.0),
          title: Text(
            "Queda do membro superior",
            style: TextStyle(
                color: Color.fromRGBO(44, 73, 108, 1.0), fontSize: 16),
          ),
          trailing: Checkbox(
            value: widget.values[1],
            onChanged: (e) {
              widget.values[1] = e;
              widget.callback(widget.values);
            },
          ),
        ),
        ListTile(
          tileColor: Color.fromRGBO(233, 237, 244, 1.0),
          title: Text(
            "Alteração na fala",
            style: TextStyle(
                color: Color.fromRGBO(44, 73, 108, 1.0), fontSize: 16),
          ),
          trailing: Checkbox(
            value: widget.values[2],
            onChanged: (e) {
              widget.values[2] = e;
              widget.callback(widget.values);
            },
          ),
        )
      ],
    );
  }
}
