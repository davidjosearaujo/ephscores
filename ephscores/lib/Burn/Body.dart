import 'dart:ui';

class Body {
  String primaryName;
  String path;
  Color color;
  int degree;

  Body(this.primaryName, this.color, this.degree, this.path);

  severity() {
    if (this.degree < 3) {
      this.degree++;
    } else {
      this.degree = 0;
    }

    switch (this.degree) {
      case 0:
        this.color = Color.fromRGBO(208, 216, 232, 1);
        break;
      case 1:
        this.color = Color.fromRGBO(52, 168, 83, 1);
        break;
      case 2:
        this.color = Color.fromRGBO(251, 188, 4, 1);
        break;
      case 3:
        this.color = Color.fromRGBO(234, 67, 53, 1);
        break;
    }
  }
}
