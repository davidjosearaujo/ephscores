import 'package:flutter/material.dart';

class STARTList extends StatefulWidget {
  STARTList({Key key, this.title}) : super(key: key);
  final String title;
  int p1 = 0, p2 = 0, p3 = 0, p4 = 0;

  @override
  _STARTListState createState() => _STARTListState();
}

class _STARTListState extends State<STARTList> {
  var isSelected = [false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lista",
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(79, 129, 189, 1.0),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextButton(
                    child: Text(
                      "${widget.p1}",
                      style: TextStyle(
                        fontSize: 80,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        return Color.fromRGBO(234, 67, 53, 1.0);
                      }),
                    ),
                    onPressed: () {},
                  ),
                ),
                Expanded(
                  child: TextButton(
                    child: Text(
                      "${widget.p2}",
                      style: TextStyle(
                        fontSize: 80,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        return Color.fromRGBO(251, 188, 4, 1.0);
                      }),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextButton(
                    child: Text(
                      "${widget.p3}",
                      style: TextStyle(
                        fontSize: 80,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        return Color.fromRGBO(52, 168, 83, 1.0);
                      }),
                    ),
                    onPressed: () {},
                  ),
                ),
                Expanded(
                  child: TextButton(
                    child: Text(
                      "${widget.p4}",
                      style: TextStyle(
                        fontSize: 80,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        return Colors.black;
                      }),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
