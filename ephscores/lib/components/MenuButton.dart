import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class MenuButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final String path;

  const MenuButton({
    Key key,
    this.text = "New Button",
    this.icon = Icons.add,
    this.path = "/home"
  }) : super(key: key);

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Column(
        children: [
          Icon(widget.icon),
          Text(
            widget.text,
            softWrap: true,
          ),
        ],
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed))
              return Colors.white;
            return Color.fromARGB(255, 223, 226, 232);
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return Color.fromRGBO(44, 73, 108, 1.0);
          },
        ),
      ),
      onPressed: () {
        Navigator.pushNamed(context, widget.path);
      },
    );
  }
}
