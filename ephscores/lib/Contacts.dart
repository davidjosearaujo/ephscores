import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;

class Contacts extends StatefulWidget {
  Contacts({Key key}) : super(key: key);

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  List<Map<String, dynamic>> contacts = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> filtered = <Map<String, dynamic>>[];
  JsonDecoder decoder = JsonDecoder();

  // TODO Write local database if non-existing
  // TODO Create list of contacts
  // TODO Filter the contact onChange of the TextField of search

  Future<bool> _loadAsset() async {
    String value = await rootBundle.loadString('assets/Contacts.json');
    for (Map<String, dynamic> x in decoder.convert(value)["contacts"]) {
      contacts.add(x);
      filtered.add(x);
    }
    
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadAsset().then((value) => setState(() {}));
  }

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
                onChanged: (e) {
                  print(contacts[0]["title"]);
                  setState(() {
                    filtered = contacts.where((element) =>
                        element["title"].toLowerCase().contains(e.toLowerCase())).toList();
                  });
                },
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(
                            filtered[index]["title"],
                            style: TextStyle(
                              fontSize: 26,
                            ),
                          ),
                          subtitle: Text(
                            filtered[index]["description"],
                          ),
                          textColor: Color.fromRGBO(44, 73, 108, 1.0),
                          trailing: GestureDetector(
                            child: Icon(Icons.phone,
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                size: 36),
                            onTap: () async {
                              final Uri launchUri = Uri(
                                scheme: 'tel',
                                path: filtered[index]["number"],
                              );
                              await launchUrl(launchUri);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
