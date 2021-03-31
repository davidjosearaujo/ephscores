import 'package:flutter/material.dart';

class STARTList extends StatefulWidget {
  int p1, p2, p3, p4;
  
  STARTList({this.p1=0, this.p2=0, this.p3=0, this.p4=0});
  
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
          "Sumário",
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(79, 129, 189, 1.0),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
        ],
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
                  child: Container(
                    child: Center(
                      child: Text(
                        "${widget.p1}",
                        style: TextStyle(
                            fontSize: 80,
                            color: Color.fromRGBO(79, 129, 189, 1.0)),
                      ),
                    ),
                    color: Color.fromRGBO(234, 67, 53, 1.0),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: Center(
                      child: Text(
                        "${widget.p2}",
                        style: TextStyle(
                            fontSize: 80,
                            color: Color.fromRGBO(79, 129, 189, 1.0)),
                      ),
                    ),
                    color: Color.fromRGBO(251, 188, 4, 1.0),
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
                  child: Container(
                    child: Center(
                      child: Text(
                        "${widget.p3}",
                        style: TextStyle(
                            fontSize: 80,
                            color: Color.fromRGBO(79, 129, 189, 1.0)),
                      ),
                    ),
                    color: Color.fromRGBO(52, 168, 83, 1.0),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: Center(
                      child: Text(
                        "${widget.p4}",
                        style: TextStyle(
                            fontSize: 80,
                            color: Color.fromRGBO(79, 129, 189, 1.0)),
                      ),
                    ),
                    color: Colors.black,
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
