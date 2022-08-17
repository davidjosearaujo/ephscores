import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:url_launcher/url_launcher.dart';


class Contact extends StatefulWidget {
  final String title;
  final String description;
  final String number;

  const Contact({
    Key key,
    this.title: "Title",
    this.description: "Description",
    this.number: "",
  }) : super(key: key);

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {

  Future<void> _makePhoneCall() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: widget.number,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(widget.title),
            subtitle: Text("Subtitle"),
            textColor: Color.fromRGBO(44, 73, 108, 1.0),
            trailing: GestureDetector(
              child: Icon(
                Icons.phone,
                color: Color.fromRGBO(44, 73, 108, 1.0),
              ),
              onTap: _makePhoneCall,
            ),
          ),
        ],
      ),
    );
  }
}
