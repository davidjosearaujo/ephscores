import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Posterior extends StatefulWidget {
  Function callback;

  Posterior(this.callback);

  @override
  _PosteriorState createState() => _PosteriorState();
}

class _PosteriorState extends State<Posterior> {
  double _perc = 0;

  List<Color> _colors = List.filled(7, Color.fromRGBO(79, 129, 189, 1));

  final List<Color> _sev = [
    Color.fromRGBO(79, 129, 189, 1), // Blue
    Color.fromRGBO(251, 188, 4, 1), // Yellow
    Color.fromRGBO(255, 153, 51, 1), // Orange
    Color.fromRGBO(234, 67, 53, 1) // Red
  ];

  _nextColor(Color x, double y) {
    if (x == Color.fromRGBO(79, 129, 189, 1)) {
      _perc += y;
      widget.callback(_perc);
      return Color.fromRGBO(251, 188, 4, 1);
    } else if (x == Color.fromRGBO(251, 188, 4, 1)) {
      return Color.fromRGBO(255, 153, 51, 1);
    } else if (x == Color.fromRGBO(255, 153, 51, 1)) {
      return Color.fromRGBO(234, 67, 53, 1);
    } else {
      _perc -= y;
      widget.callback(_perc);
      return Color.fromRGBO(79, 129, 189, 1);
    }
  }

  _resetColor(Color x, double y) {
    if (x != Color.fromRGBO(79, 129, 189, 1)) {
      _perc -= y;
      widget.callback(_perc);
    }
    return Color.fromRGBO(79, 129, 189, 1);
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
                style: TextStyle(color: Color.fromRGBO(79, 129, 189, 1)),
              )),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _colors[0] = _nextColor(_colors[0], 4.5);
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _colors[0] = _resetColor(_colors[0], 4.5);
                      });
                    },
                    child: SvgPicture.asset("assets/Back/head_back.svg",
                        color: _colors[0])),
              ),
              Expanded(
                  child: Text(
                "Esq",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color.fromRGBO(79, 129, 189, 1)),
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
                          _colors[1] = _nextColor(_colors[1], 4.5);
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _colors[1] = _resetColor(_colors[1], 4.5);
                        });
                      },
                      child: SvgPicture.asset(
                          "assets/Back/right_arm_back.svg",
                          color: _colors[1]))),
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
                              _colors[2] = _nextColor(_colors[2], 9.0);
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _colors[2] = _resetColor(_colors[2], 9.0);
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Back/upper_torso_back.svg",
                              color: _colors[2]),
                        )),
                    Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _colors[3] = _nextColor(_colors[3], 9.0);
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _colors[3] = _resetColor(_colors[3], 9.0);
                            });
                          },
                          child: SvgPicture.asset(
                              "assets/Back/lower_torso_back.svg",
                              color: _colors[3]),
                        )),
                  ],
                ),
              ),
              Flexible(
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _colors[4] = _nextColor(_colors[4], 4.5);
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _colors[4] = _resetColor(_colors[4], 4.5);
                        });
                      },
                      child: SvgPicture.asset("assets/Back/left_arm_back.svg",
                          color: _colors[4]))),
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
                        _colors[5] = _nextColor(_colors[5], 9.0);
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _colors[5] = _resetColor(_colors[5], 9.0);
                      });
                    },
                    child: SvgPicture.asset("assets/Back/right_leg_back.svg",
                        color: _colors[5])),
              ),
              Expanded(
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _colors[6] = _nextColor(_colors[6], 9.0);
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _colors[6] = _resetColor(_colors[6], 9.0);
                      });
                    },
                    child: SvgPicture.asset("assets/Back/left_leg_back.svg",
                        color: _colors[6])),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

