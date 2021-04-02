import 'package:flutter/material.dart';

class Cincinnati extends StatefulWidget {
  @override
  _CincinnatiState createState() => _CincinnatiState();
}

class _CincinnatiState extends State<Cincinnati> {
  List<bool> cincinnati = List<bool>.filled(3, false);

  int cincinattiCount() {
    int c = 0;
    for (bool x in cincinnati) {
      if (x) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
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
            value: cincinnati[0],
            onChanged: (e) {
              setState(() {
                cincinnati[0] = e;
                cincinattiCount();
              });
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
            value: cincinnati[1],
            onChanged: (e) {
              setState(() {
                cincinnati[1] = e;
                cincinattiCount();
              });
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
            value: cincinnati[2],
            onChanged: (e) {
              setState(() {
                cincinnati[2] = e;
                cincinattiCount();
              });
            },
          ),
        )
      ],
    );
  }
}
