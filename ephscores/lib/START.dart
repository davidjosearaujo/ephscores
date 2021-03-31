import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

class START extends StatefulWidget {
  int p1, p2, p3, p4;

  START({this.p1 = 0, this.p2 = 0, this.p3 = 0, this.p4 = 0});

  @override
  _STARTState createState() => _STARTState();
}

class _STARTState extends State<START> {
  int page = 0;
  String title = "Triagem START";
  Widget body;
  List<bool> isSelected = [false, false, false, false, false, false];
  List<bool> isEnabled = [true, true, true, true, true, true];

  Color evaluation() {
    if (isSelected[0]) {
      return Color.fromRGBO(52, 168, 83, 1.0);
    } else {
      if (isSelected[1]) {
        if (isSelected[4] || isSelected[2]) {
          return Color.fromRGBO(234, 67, 53, 1.0);
        }else if(isSelected[4]){
          return Color.fromRGBO(234, 67, 53, 1.0);
        }else if(isSelected[5]){
          return Color.fromRGBO(251, 188, 4, 1.0);
        }else{
          return Color.fromRGBO(234, 67, 53, 1.0);
        }
      } else {
        return Colors.black;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (page) {
      case 1:
        title = "Sumário";
        body = Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      child: Center(
                        child: Text(
                          "${widget.p1}",
                          style: TextStyle(
                              fontSize: 80,
                              color: Color.fromRGBO(79, 129, 189, 1.0)),
                        ),
                      ),
                      color: Color.fromRGBO(234, 67, 53, 1.0),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      child: Center(
                        child: Text(
                          "${widget.p2}",
                          style: TextStyle(
                              fontSize: 80,
                              color: Color.fromRGBO(79, 129, 189, 1.0)),
                        ),
                      ),
                      color: Color.fromRGBO(251, 188, 4, 1.0),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      child: Center(
                        child: Text(
                          "${widget.p3}",
                          style: TextStyle(
                              fontSize: 80,
                              color: Color.fromRGBO(79, 129, 189, 1.0)),
                        ),
                      ),
                      color: Color.fromRGBO(52, 168, 83, 1.0),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      child: Center(
                        child: Text(
                          "${widget.p4}",
                          style: TextStyle(
                              fontSize: 80,
                              color: Color.fromRGBO(79, 129, 189, 1.0)),
                        ),
                      ),
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
      default:
        title = "Triagem START";
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                flex: 1,
                child: Container(
                  color: evaluation(),
                )),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSelected[0] = !isSelected[0];
                        });
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: ((st) {
                            return st
                                ? Color.fromRGBO(208, 216, 232, 1.0)
                                : Color.fromRGBO(233, 237, 244, 1.0);
                          })(isSelected[0]),
                          side: BorderSide(
                            color: Colors.white,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.directions_walk_rounded,
                              size: 70,
                              color: Color.fromRGBO(44, 73, 108, 1.0)),
                          Text(
                            "Caminha",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSelected[1] = !isSelected[1];
                        });
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: ((st) {
                            return st
                                ? Color.fromRGBO(208, 216, 232, 1.0)
                                : Color.fromRGBO(233, 237, 244, 1.0);
                          })(isSelected[1]),
                          side: BorderSide(
                            color: Colors.white,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(WeatherIcons.windy,
                              size: 70,
                              color: Color.fromRGBO(44, 73, 108, 1.0)),
                          Text(
                            "Respira",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSelected[2] = !isSelected[2];
                        });
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: ((st) {
                            return st
                                ? Color.fromRGBO(208, 216, 232, 1.0)
                                : Color.fromRGBO(233, 237, 244, 1.0);
                          })(isSelected[2]),
                          side: BorderSide(
                            color: Colors.white,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.autorenew_rounded,
                              size: 70,
                              color: Color.fromRGBO(44, 73, 108, 1.0)),
                          Text(
                            "+30 ciclos/min",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSelected[3] = !isSelected[3];
                        });
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: ((st) {
                            return st
                                ? Color.fromRGBO(208, 216, 232, 1.0)
                                : Color.fromRGBO(233, 237, 244, 1.0);
                          })(isSelected[3]),
                          side: BorderSide(
                            color: Colors.white,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 70,
                              color: Color.fromRGBO(44, 73, 108, 1.0)),
                          Text(
                            "Adjuvantes",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSelected[4] = !isSelected[4];
                        });
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: ((st) {
                            return st
                                ? Color.fromRGBO(208, 216, 232, 1.0)
                                : Color.fromRGBO(233, 237, 244, 1.0);
                          })(isSelected[4]),
                          side: BorderSide(
                            color: Colors.white,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 70,
                              color: Color.fromRGBO(44, 73, 108, 1.0)),
                          Text(
                            "PC >2 seg",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isSelected[5] = !isSelected[5];
                        });
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: ((st) {
                            return st
                                ? Color.fromRGBO(208, 216, 232, 1.0)
                                : Color.fromRGBO(233, 237, 244, 1.0);
                          })(isSelected[5]),
                          side: BorderSide(
                            color: Colors.white,
                          )),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined,
                              size: 70,
                              color: Color.fromRGBO(44, 73, 108, 1.0)),
                          Text(
                            "Cumpre ordens",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
        break;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(fontSize: 24),
          ),
          backgroundColor: Color.fromRGBO(79, 129, 189, 1.0),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
          ],
        ),
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color.fromRGBO(208, 216, 232, 1.0),
          selectedItemColor: Color.fromRGBO(79, 129, 189, 1.0),
          unselectedItemColor: Color.fromRGBO(44, 73, 108, 1.0),
          iconSize: 30,
          currentIndex: page,
          onTap: (int e) {
            setState(() {
              e == 1 ? page = 1 : page = 0;
            });
          },
          items: [
            BottomNavigationBarItem(
              title: Text("Triagem"),
              icon: Icon(Icons.warning),
            ),
            BottomNavigationBarItem(
              title: Text("Sumário"),
              icon: Icon(Icons.list),
            ),
          ],
        ));
  }
}
