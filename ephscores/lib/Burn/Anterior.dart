import 'package:ephscores/Burn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class Anterior extends StatefulWidget {
  final RefreshController controller;
  Function callfront;
  SharedPreferences prefs;
  double perc;

  Anterior(this.callfront, this.perc, this.prefs, this.controller);

  @override
  _AnteriorState createState() => _AnteriorState(controller);
}

class _AnteriorState extends State<Anterior> {
  _AnteriorState(RefreshController _controller) {
    _controller.method = refresh;
  }

  List<Color> _limbs = List.filled(8, Color.fromRGBO(44, 73, 108, 1.0));

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
        _limbs[2] = _colors[value.containsKey("upper_torso_front")
            ? value.getInt("upper_torso_front")
            : 0];
        _limbs[3] = _colors[value.containsKey("lower_torso_front")
            ? value.getInt("lower_torso_front")
            : 0];
        _limbs[4] = _colors[value.containsKey("genitals_front")
            ? value.getInt("genitals_front")
            : 0];
        _limbs[5] = _colors[value.containsKey("left_arm_front")
            ? value.getInt("left_arm_front")
            : 0];
        _limbs[6] = _colors[value.containsKey("right_leg_front")
            ? value.getInt("right_leg_front")
            : 0];
        _limbs[7] = _colors[value.containsKey("left_leg_front")
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
        widget.callfront(widget.perc);
        break;
      }
    }
    refresh();
  }

  void _resetColor(Color x, double y, String id) async {
    widget.prefs = await SharedPreferences.getInstance();
    if (x != Color.fromRGBO(44, 73, 108, 1.0)) {
      widget.perc -= y;
      widget.callfront(widget.perc);
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
          flex: 3,
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
                        _nextColor(_limbs[0], 4.5, "head_front");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[0], 4.5, "head_front");
                      });
                    },
                    child: SvgPicture.asset("assets/Front/head_front.svg",
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
                      child: SvgPicture.asset(
                          "assets/Front/right_arm_front.svg",
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
                              _nextColor(_limbs[2], 9.0, "upper_torso_front");
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _resetColor(_limbs[2], 9.0, "upper_torso_front");
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Front/upper_torso_front.svg",
                              color: _limbs[2]),
                        )),
                    Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _nextColor(_limbs[3], 9.0, "lower_torso_front");
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _resetColor(_limbs[3], 9.0, "lower_torso_front");
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Front/lower_torso_front.svg",
                              color: _limbs[3]),
                        )),
                    Expanded(
                        flex: 1,
                        child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _nextColor(_limbs[4], 1.0, "genitals_front");
                              });
                            },
                            onLongPress: () {
                              setState(() {
                                _resetColor(_limbs[4], 1.0, "genitals_front");
                              });
                            },
                            child: SvgPicture.asset(
                                "assets/Front/genitals_front.svg",
                                color: _limbs[4]))),
                  ],
                ),
              ),
              Flexible(
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _nextColor(_limbs[5], 4.5, "left_arm_front");
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _resetColor(_limbs[5], 4.5, "left_arm_front");
                        });
                      },
                      child: SvgPicture.asset("assets/Front/left_arm_front.svg",
                          color: _limbs[5]))),
            ],
          ),
        ),
        Expanded(
          flex: 9,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _nextColor(_limbs[6], 9.0, "right_leg_front");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[6], 9.0, "right_leg_front");
                      });
                    },
                    child: SvgPicture.asset("assets/Front/right_leg_front.svg",
                        color: _limbs[6])),
              ),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _nextColor(_limbs[7], 9.0, "left_leg_front");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[7], 9.0, "left_leg_front");
                      });
                    },
                    child: SvgPicture.asset("assets/Front/left_leg_front.svg",
                        color: _limbs[7])),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
