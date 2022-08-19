import 'package:ephscores/Burn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class Anterior extends StatefulWidget {
  final RefreshController controller;
  Function callback;
  SharedPreferences prefs;
  double perc;

  Anterior(this.callback, this.perc, this.prefs, this.controller);

  @override
  _AnteriorState createState() => _AnteriorState(controller);
}

class _AnteriorState extends State<Anterior> {

  _AnteriorState(RefreshController _controller) {
    _controller.method = refresh;
  }

  List<Color> _limbs = List.filled(6, Color.fromRGBO(44, 73, 108, 1.0));

  final List<Color> _colors = [
    Color.fromRGBO(44, 73, 108, 1.0), // Blue
    Color.fromRGBO(251, 188, 4, 1), // Yellow
    Color.fromRGBO(255, 153, 51, 1), // Orange
    Color.fromRGBO(234, 67, 53, 1) // Red
  ];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    SharedPreferences.getInstance().then((value) {
      setState(() {
        _limbs[0] = _colors[
            value.containsKey("head_front") ? value.getInt("head_front") : 0];
        _limbs[1] = _colors[value.containsKey("right_arm_front")
            ? value.getInt("right_arm_front")
            : 0];
        _limbs[2] = _colors[value.containsKey("torso_front")
            ? value.getInt("torso_front")
            : 0];
        _limbs[3] = _colors[value.containsKey("left_arm_front")
            ? value.getInt("left_arm_front")
            : 0];
        _limbs[4] = _colors[value.containsKey("right_leg_front")
            ? value.getInt("right_leg_front")
            : 0];
        _limbs[5] = _colors[value.containsKey("left_leg_front")
            ? value.getInt("left_leg_front")
            : 0];
      });
    });
  }

  void _nextColor(Color x, double y, String id) async {
    widget.prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _colors.length; i++) {
      if (x == _colors[i]) {
        if (i == 0) {
          widget.perc += y;
        } else if (i == 3) {
          widget.perc -= y;
        }
        widget.prefs.setInt(id, (i == 3 ? 0 : i + 1));
        widget.callback(widget.perc);
      }
    }
    refresh();
  }

  void _resetColor(Color x, double y, String id) async {
    widget.prefs = await SharedPreferences.getInstance();
    if (x != Color.fromRGBO(44, 73, 108, 1.0)) {
      widget.perc -= y;
      widget.callback(widget.perc);
    }
    widget.prefs.setInt(id, 0);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Text(
                "Dir",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
              )),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _nextColor(_limbs[0], 9, "head_front");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[0], 9, "head_front");
                      });
                    },
                    child: SvgPicture.asset("assets/Ped/head.svg",
                        color: _limbs[0])),
              ),
              Expanded(
                  child: Text(
                "Esq",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color.fromRGBO(44, 73, 108, 1.0)),
              )),
            ],
          ),
        ),
        Expanded(
          flex: 7,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _nextColor(_limbs[1], 4.5, "right_arm_front");
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _resetColor(_limbs[1], 4.5, "right_arm_front");
                        });
                      },
                      child: SvgPicture.asset("assets/Ped/right_arm.svg",
                          color: _limbs[1]))),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _nextColor(_limbs[2], 18.0, "torso_front");
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _resetColor(_limbs[2], 18.0, "torso_front");
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Ped/torso.svg",
                              color: _limbs[2]),
                        )),
                  ],
                ),
              ),
              Flexible(
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _nextColor(_limbs[3], 4.5, "left_arm_front");
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _resetColor(_limbs[3], 4.5, "left_arm_front");
                        });
                      },
                      child: SvgPicture.asset("assets/Ped/left_arm.svg",
                          color: _limbs[3]))),
            ],
          ),
        ),
        Expanded(
          flex: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _nextColor(_limbs[4], 7.0, "right_leg_front");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[4], 7.0, "right_leg_front");
                      });
                    },
                    child: SvgPicture.asset("assets/Ped/right_leg.svg",
                        color: _limbs[4])),
              ),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _nextColor(_limbs[5], 7.0, "left_leg_front");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[5], 7.0, "left_leg_front");
                      });
                    },
                    child: SvgPicture.asset("assets/Ped/left_leg.svg",
                        color: _limbs[5])),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
