import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'components/Contact.dart';
import 'package:flutter/services.dart' show rootBundle;

class Contacts extends StatefulWidget {
  List<Contact> contacts;

  Contacts({Key key}) : super(key: key);

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  JsonDecoder decoder = JsonDecoder();

  // TODO Write local database if non-existing
  // TODO Create list of contacts
  // TODO Filter the contact onChange of the TextField of search

  Future<String> loadAsset() async {
    return await rootBundle.loadString('assets/Contacts.json');
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      Contact y;
      loadAsset().then((value) => {
        for(Map<String, dynamic> x in decoder.convert(value)["contacts"]){
          //widget.contacts.addd()
        }
      });
    });
  }

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
