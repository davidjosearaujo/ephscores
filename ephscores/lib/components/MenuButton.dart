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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: .5,
              blurRadius: 1,
              offset: Offset(1, 2), // changes position of shadow
            ),
          ],
          gradient: LinearGradient(
              colors: [Color.fromARGB(255, 244, 247, 241), Colors.white],
              begin: const FractionalOffset(0.0, 0.0),
              end: const FractionalOffset(0.9, 0.0),
              stops: [0.0, 7.0],
              tileMode: TileMode.clamp),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: Color.fromRGBO(44, 73, 108, 0.2),
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: Container(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Color.fromRGBO(44, 73, 108, 1.0),
                          fontSize: 24
                        ),
                      ),
                    ),
                    Icon(
                      widget.icon,
                      size: 80,
                      color: Color.fromRGBO(44, 73, 108, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
