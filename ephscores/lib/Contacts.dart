import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'components/Contact.dart';

class Contacts extends StatefulWidget {
  //final List<Contact  > contacts;

  const Contacts({Key key}) : super(key: key);

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  // TODO Read online database
  // TODO Write local database if non-existing
  // TODO Create list of contacts
  // TODO Filter the contact onChange of the TextField of search

  void _updateList(String e) {}

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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: TextField(
                style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
                cursorColor: Color.fromRGBO(44, 73, 108, 1.0),
                decoration: InputDecoration(
                    labelText: "Procurar",
                    labelStyle:
                        TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromRGBO(44, 73, 108, 1.0)),
                    ),
                    suffixIcon: Icon(
                      Icons.search,
                      color: Color.fromRGBO(44, 73, 108, 1.0),
                    )),
                onChanged: _updateList,
              ),
            ),
            ListView(shrinkWrap: true, children: [
              Contact(),
            ]),
          ],
        ),
      ),
    );
  }
}
