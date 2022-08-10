import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class MenuButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Function onPressed;

  const MenuButton(
      {Key key,
      this.text = "New Button",
      this.icon = Icons.add,
      this.onPressed})
      : super(key: key);

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      highlightColor: Colors.transparent,
      splashColor: Color.fromARGB(100, 0, 255, 229),
      borderRadius: BorderRadius.all(Radius.circular(5)),
      child: Card(
        color: Color.fromARGB(255, 223, 226, 232),
        child: Container(
          alignment: Alignment.center,
          width: 100,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 50,
                color: Color.fromRGBO(44, 73, 108, 1.0),
              ),
              Text(
                widget.text,
                softWrap: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromRGBO(44, 73, 108, 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: widget.onPressed,
    );
  }
}
