import 'package:ephscores/Burn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class Posterior extends StatefulWidget {
  final RefreshController controller;
  Function callback;
  SharedPreferences prefs;
  double perc;

  Posterior(this.callback, this.perc, this.prefs, this.controller);

  @override
  _PosteriorState createState() => _PosteriorState(controller);
}

class _PosteriorState extends State<Posterior> {

  _PosteriorState(RefreshController _controller) {
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
            value.containsKey("head_back") ? value.getInt("head_back") : 0];
        _limbs[1] = _colors[value.containsKey("right_arm_back")
            ? value.getInt("right_arm_back")
            : 0];
        _limbs[2] = _colors[value.containsKey("upper_torso_back")
            ? value.getInt("upper_torso_back")
            : 0];
        _limbs[3] = _colors[value.containsKey("lower_torso_back")
            ? value.getInt("lower_torso_back")
            : 0];
        _limbs[4] = _colors[value.containsKey("left_arm_back")
            ? value.getInt("left_arm_back")
            : 0];
        _limbs[5] = _colors[value.containsKey("right_leg_back")
            ? value.getInt("right_leg_back")
            : 0];
        _limbs[6] = _colors[value.containsKey("left_leg_back")
            ? value.getInt("left_leg_back")
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
                        _nextColor(_limbs[0], 4.5, "head_back");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[0], 4.5, "head_back");
                      });
                    },
                    child: SvgPicture.asset("assets/Back/head_back.svg",
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
                          _nextColor(_limbs[1], 4.5, "right_arm_back");
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _resetColor(_limbs[1], 4.5, "right_arm_back");
                        });
                      },
                      child: SvgPicture.asset("assets/Back/right_arm_back.svg",
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
                              _nextColor(_limbs[2], 9.0, "upper_torso_back");
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _resetColor(_limbs[2], 9.0, "upper_torso_back");
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Back/upper_torso_back.svg",
                              color: _limbs[2]),
                        )),
                    Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _nextColor(_limbs[3], 9.0, "lower_torso_back");
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _resetColor(_limbs[3], 9.0, "lower_torso_back");
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Back/lower_torso_back.svg",
                              color: _limbs[3]),
                        )),
                  ],
                ),
              ),
              Flexible(
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _nextColor(_limbs[4], 4.5, "left_arm_back");
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _resetColor(_limbs[4], 4.5, "left_arm_back");
                        });
                      },
                      child: SvgPicture.asset("assets/Back/left_arm_back.svg",
                          color: _limbs[4]))),
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
                        _nextColor(_limbs[5], 9.0, "right_leg_back");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[5], 9.0, "right_leg_back");
                      });
                    },
                    child: SvgPicture.asset("assets/Back/right_leg_back.svg",
                        color: _limbs[5])),
              ),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _nextColor(_limbs[6], 9.0, "left_leg_back");
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _resetColor(_limbs[6], 9.0, "left_leg_back");
                      });
                    },
                    child: SvgPicture.asset("assets/Back/left_leg_back.svg",
                        color: _limbs[6])),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
