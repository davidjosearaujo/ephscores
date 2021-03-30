import 'package:flutter/material.dart';

class START extends StatefulWidget {
  @override
  _STARTState createState() => _STARTState();
}

class _STARTState extends State<START> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Triagem START",
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Color.fromRGBO(79, 129, 189, 1.0),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
        ],
      ),
      //body:
      bottomNavigationBar: ButtonBar(
        alignment: MainAxisAlignment.spaceEvenly
        children: [
          
        ],
      ),
    );
  }
}
