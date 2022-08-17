import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class Contacts extends StatefulWidget {
  const Contacts({Key key}) : super(key: key);

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Color.fromRGBO(44, 73, 108, 1.0),
        shadowColor: Colors.transparent,
        title: Text(
          "Contactos Importantes",
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.grey.shade100,
                  child: Text(
                    "Hello"
                  ),
                )
              ],
          )),
      ]),
    );
  }
}
