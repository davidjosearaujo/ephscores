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
  String state = "P3";
  Widget body;
  List<bool> isSelected = [false, false];

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
                  color: ((state) {
                    Color col = Color.fromRGBO(52, 168, 83, 1.0);
                    switch (state) {
                      case "P1":
                        col = Color.fromRGBO(234, 67, 53, 1.0);
                        break;
                      case "P2":
                        col = Color.fromRGBO(251, 188, 4, 1.0);
                        break;
                      case "P3":
                        col = Color.fromRGBO(52, 168, 83, 1.0);
                        break;
                    }
                    return col;
                  })(state),
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
                      onPressed: (){},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          border: Border.all(
                              color: Color.fromRGBO(208, 216, 232, 1.0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.directions_walk_rounded,
                                size: 80,
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            Text(
                              "Caminha",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromRGBO(44, 73, 108, 1.0),
                                fontSize: 24
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(233, 237, 244, 1.0),
                          border: Border.all(
                              color: Color.fromRGBO(208, 216, 232, 1.0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(WeatherIcons.windy,
                                size: 80,
                                color: Color.fromRGBO(44, 73, 108, 1.0)),
                            Text(
                              "Respira",
                              style: TextStyle(
                                  color: Color.fromRGBO(44, 73, 108, 1.0),
                                  fontSize: 24),
                            ),
                          ],
                        ),
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
                      onPressed: () {},
                      child: Text("+30 ciclos/min"),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {},
                      child: Text("Adjuvantes"),
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
                      onPressed: () {},
                      child: Text("PC >2 seg"),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () {},
                      child: Text("Cumpre ordens"),
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
