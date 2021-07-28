import 'package:flutter/material.dart';

class Anterior extends StatefulWidget {
  const Anterior();

  @override
  _AnteriorState createState() => _AnteriorState();
}

class _AnteriorState extends State<Anterior> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FrontPainter(),
      child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height
      )        
    );
  }
}

class _FrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number rightleg
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.03, size.height * 1.82);
    path.cubicTo(size.width * 1.04, size.height * 1.82, size.width * 1.08,
        size.height * 1.82, size.width * 1.11, size.height * 1.81);
    path.cubicTo(size.width * 1.13, size.height * 1.8, size.width * 1.17,
        size.height * 1.8, size.width * 1.19, size.height * 1.8);
    path.cubicTo(size.width * 1.21, size.height * 1.79, size.width * 1.23,
        size.height * 1.79, size.width * 1.24, size.height * 1.79);
    path.cubicTo(size.width * 1.26, size.height * 1.78, size.width * 1.27,
        size.height * 1.76, size.width * 1.28, size.height * 1.73);
    path.cubicTo(size.width * 1.29, size.height * 1.68, size.width * 1.29,
        size.height * 1.67, size.width * 1.27, size.height * 1.66);
    path.cubicTo(size.width * 1.24, size.height * 1.64, size.width * 1.25,
        size.height * 1.61, size.width * 1.3, size.height * 1.56);
    path.cubicTo(size.width * 1.37, size.height * 1.5, size.width * 1.37,
        size.height * 1.48, size.width * 1.34, size.height * 1.43);
    path.cubicTo(size.width * 1.33, size.height * 1.41, size.width * 1.32,
        size.height * 1.39, size.width * 1.32, size.height * 1.38);
    path.cubicTo(size.width * 1.32, size.height * 1.36, size.width * 1.32,
        size.height * 1.36, size.width * 1.34, size.height * 1.35);
    path.cubicTo(size.width * 1.36, size.height * 1.34, size.width * 1.39,
        size.height * 1.31, size.width * 1.41, size.height * 1.28);
    path.cubicTo(size.width * 1.42, size.height * 1.25, size.width * 1.43,
        size.height * 1.19, size.width * 1.41, size.height * 1.17);
    path.cubicTo(size.width * 1.41, size.height * 1.15, size.width * 1.41,
        size.height * 1.15, size.width * 1.42, size.height * 1.14);
    path.cubicTo(size.width * 1.43, size.height * 1.14, size.width * 1.44,
        size.height * 1.13, size.width * 1.44, size.height * 1.13);
    path.cubicTo(size.width * 1.44, size.height * 1.13, size.width * 1.45,
        size.height * 1.12, size.width * 1.45, size.height * 1.11);
    path.cubicTo(size.width * 1.48, size.height * 1.08, size.width * 1.5,
        size.height * 1.04, size.width * 1.51, size.height);
    path.cubicTo(size.width * 1.52, size.height, size.width * 1.52,
        size.height * 0.95, size.width * 1.51, size.height * 0.95);
    path.cubicTo(size.width * 1.51, size.height * 0.95, size.width * 1.49,
        size.height * 0.94, size.width * 1.46, size.height * 0.94);
    path.cubicTo(size.width * 1.36, size.height * 0.92, size.width * 1.27,
        size.height * 0.89, size.width * 1.23, size.height * 0.87);
    path.cubicTo(size.width * 1.21, size.height * 0.87, size.width * 1.19,
        size.height * 0.86, size.width * 1.18, size.height * 0.85);
    path.cubicTo(size.width * 1.14, size.height * 0.84, size.width * 1.13,
        size.height * 0.83, size.width * 1.13, size.height * 0.83);
    path.cubicTo(size.width * 1.13, size.height * 0.83, size.width * 1.12,
        size.height * 0.83, size.width * 1.12, size.height * 0.83);
    path.cubicTo(size.width * 1.11, size.height * 0.83, size.width * 1.1,
        size.height * 0.83, size.width * 1.09, size.height * 0.85);
    path.cubicTo(size.width * 1.08, size.height * 0.86, size.width * 1.07,
        size.height * 0.87, size.width * 1.05, size.height * 0.89);
    path.cubicTo(size.width * 1.02, size.height * 0.93, size.width,
        size.height * 0.95, size.width, size.height);
    path.cubicTo(size.width * 0.96, size.height * 1.04, size.width * 0.96,
        size.height * 1.06, size.width * 0.98, size.height * 1.1);
    path.cubicTo(size.width, size.height * 1.14, size.width * 1.06,
        size.height * 1.21, size.width * 1.1, size.height * 1.23);
    path.cubicTo(size.width * 1.11, size.height * 1.24, size.width * 1.11,
        size.height * 1.25, size.width * 1.11, size.height * 1.29);
    path.cubicTo(size.width * 1.12, size.height * 1.34, size.width * 1.12,
        size.height * 1.34, size.width * 1.1, size.height * 1.35);
    path.cubicTo(size.width * 1.05, size.height * 1.39, size.width * 1.02,
        size.height * 1.44, size.width * 1.03, size.height * 1.5);
    path.cubicTo(size.width * 1.04, size.height * 1.54, size.width * 1.07,
        size.height * 1.59, size.width * 1.11, size.height * 1.62);
    path.cubicTo(size.width * 1.13, size.height * 1.63, size.width * 1.13,
        size.height * 1.66, size.width * 1.11, size.height * 1.69);
    path.cubicTo(size.width * 1.11, size.height * 1.69, size.width * 1.1,
        size.height * 1.72, size.width * 1.1, size.height * 1.72);
    path.cubicTo(size.width * 1.1, size.height * 1.72, size.width * 1.04,
        size.height * 1.74, size.width * 1.04, size.height * 1.74);
    path.cubicTo(size.width * 1.02, size.height * 1.75, size.width * 0.96,
        size.height * 1.76, size.width * 0.93, size.height * 1.77);
    path.cubicTo(size.width * 0.87, size.height * 1.78, size.width * 0.82,
        size.height * 1.8, size.width * 0.82, size.height * 1.81);
    path.cubicTo(size.width * 0.82, size.height * 1.81, size.width * 0.86,
        size.height * 1.82, size.width * 0.92, size.height * 1.82);
    path.cubicTo(size.width * 0.96, size.height * 1.83, size.width,
        size.height * 1.83, size.width * 1.03, size.height * 1.82);
    path.cubicTo(size.width * 1.03, size.height * 1.82, size.width * 1.03,
        size.height * 1.82, size.width * 1.03, size.height * 1.82);
    canvas.drawPath(path, paint);

    // Path number leftleg
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 2.23, size.height * 1.82);
    path.cubicTo(size.width * 2.25, size.height * 1.82, size.width * 2.28,
        size.height * 1.82, size.width * 2.31, size.height * 1.82);
    path.cubicTo(size.width * 2.34, size.height * 1.81, size.width * 2.35,
        size.height * 1.81, size.width * 2.35, size.height * 1.81);
    path.cubicTo(size.width * 2.35, size.height * 1.8, size.width * 2.29,
        size.height * 1.78, size.width * 2.22, size.height * 1.77);
    path.cubicTo(size.width * 2.19, size.height * 1.76, size.width * 2.16,
        size.height * 1.75, size.width * 2.12, size.height * 1.74);
    path.cubicTo(size.width * 2.12, size.height * 1.74, size.width * 2.07,
        size.height * 1.72, size.width * 2.07, size.height * 1.72);
    path.cubicTo(size.width * 2.07, size.height * 1.72, size.width * 2.06,
        size.height * 1.7, size.width * 2.06, size.height * 1.7);
    path.cubicTo(size.width * 2.05, size.height * 1.69, size.width * 2.05,
        size.height * 1.67, size.width * 2.04, size.height * 1.66);
    path.cubicTo(size.width * 2.03, size.height * 1.64, size.width * 2.03,
        size.height * 1.63, size.width * 2.05, size.height * 1.63);
    path.cubicTo(size.width * 2.07, size.height * 1.61, size.width * 2.1,
        size.height * 1.58, size.width * 2.13, size.height * 1.53);
    path.cubicTo(size.width * 2.14, size.height * 1.51, size.width * 2.14,
        size.height * 1.5, size.width * 2.14, size.height * 1.47);
    path.cubicTo(size.width * 2.14, size.height * 1.42, size.width * 2.12,
        size.height * 1.39, size.width * 2.06, size.height * 1.35);
    path.cubicTo(size.width * 2.05, size.height * 1.34, size.width * 2.04,
        size.height * 1.34, size.width * 2.05, size.height * 1.33);
    path.cubicTo(size.width * 2.05, size.height * 1.33, size.width * 2.05,
        size.height * 1.3, size.width * 2.05, size.height * 1.28);
    path.cubicTo(size.width * 2.06, size.height * 1.25, size.width * 2.06,
        size.height * 1.24, size.width * 2.07, size.height * 1.23);
    path.cubicTo(size.width * 2.08, size.height * 1.23, size.width * 2.09,
        size.height * 1.22, size.width * 2.13, size.height * 1.18);
    path.cubicTo(size.width * 2.19, size.height * 1.11, size.width * 2.21,
        size.height * 1.06, size.width * 2.2, size.height * 1.03);
    path.cubicTo(size.width * 2.19, size.height * 1.02, size.width * 2.19,
        size.height, size.width * 2.18, size.height);
    path.cubicTo(size.width * 2.17, size.height * 0.95, size.width * 2.15,
        size.height * 0.92, size.width * 2.11, size.height * 0.88);
    path.cubicTo(size.width * 2.09, size.height * 0.86, size.width * 2.07,
        size.height * 0.84, size.width * 2.07, size.height * 0.84);
    path.cubicTo(size.width * 2.07, size.height * 0.83, size.width * 2.06,
        size.height * 0.83, size.width * 2.05, size.height * 0.83);
    path.cubicTo(size.width * 2.05, size.height * 0.83, size.width * 2.03,
        size.height * 0.83, size.width * 1.95, size.height * 0.87);
    path.cubicTo(size.width * 1.91, size.height * 0.89, size.width * 1.81,
        size.height * 0.92, size.width * 1.76, size.height * 0.93);
    path.cubicTo(size.width * 1.73, size.height * 0.93, size.width * 1.7,
        size.height * 0.94, size.width * 1.68, size.height * 0.94);
    path.cubicTo(size.width * 1.68, size.height * 0.94, size.width * 1.65,
        size.height * 0.95, size.width * 1.65, size.height * 0.95);
    path.cubicTo(size.width * 1.65, size.height * 0.95, size.width * 1.65,
        size.height * 0.98, size.width * 1.65, size.height * 0.98);
    path.cubicTo(size.width * 1.65, size.height, size.width * 1.66,
        size.height * 1.02, size.width * 1.67, size.height * 1.03);
    path.cubicTo(size.width * 1.69, size.height * 1.08, size.width * 1.73,
        size.height * 1.14, size.width * 1.74, size.height * 1.14);
    path.cubicTo(size.width * 1.75, size.height * 1.14, size.width * 1.76,
        size.height * 1.15, size.width * 1.75, size.height * 1.16);
    path.cubicTo(size.width * 1.75, size.height * 1.16, size.width * 1.75,
        size.height * 1.18, size.width * 1.75, size.height * 1.2);
    path.cubicTo(size.width * 1.74, size.height * 1.25, size.width * 1.75,
        size.height * 1.28, size.width * 1.8, size.height * 1.33);
    path.cubicTo(size.width * 1.81, size.height * 1.34, size.width * 1.83,
        size.height * 1.35, size.width * 1.84, size.height * 1.35);
    path.cubicTo(size.width * 1.85, size.height * 1.36, size.width * 1.85,
        size.height * 1.36, size.width * 1.85, size.height * 1.37);
    path.cubicTo(size.width * 1.85, size.height * 1.37, size.width * 1.85,
        size.height * 1.38, size.width * 1.84, size.height * 1.39);
    path.cubicTo(size.width * 1.84, size.height * 1.4, size.width * 1.83,
        size.height * 1.41, size.width * 1.83, size.height * 1.41);
    path.cubicTo(size.width * 1.83, size.height * 1.42, size.width * 1.82,
        size.height * 1.43, size.width * 1.82, size.height * 1.44);
    path.cubicTo(size.width * 1.79, size.height * 1.48, size.width * 1.8,
        size.height * 1.5, size.width * 1.86, size.height * 1.55);
    path.cubicTo(size.width * 1.88, size.height * 1.57, size.width * 1.9,
        size.height * 1.59, size.width * 1.9, size.height * 1.6);
    path.cubicTo(size.width * 1.92, size.height * 1.61, size.width * 1.92,
        size.height * 1.64, size.width * 1.9, size.height * 1.65);
    path.cubicTo(size.width * 1.89, size.height * 1.67, size.width * 1.88,
        size.height * 1.7, size.width * 1.88, size.height * 1.7);
    path.cubicTo(size.width * 1.88, size.height * 1.71, size.width * 1.89,
        size.height * 1.72, size.width * 1.89, size.height * 1.73);
    path.cubicTo(size.width * 1.89, size.height * 1.75, size.width * 1.91,
        size.height * 1.78, size.width * 1.92, size.height * 1.79);
    path.cubicTo(size.width * 1.93, size.height * 1.79, size.width * 1.95,
        size.height * 1.79, size.width * 1.98, size.height * 1.8);
    path.cubicTo(size.width * 2.01, size.height * 1.8, size.width * 2.05,
        size.height * 1.81, size.width * 2.07, size.height * 1.81);
    path.cubicTo(size.width * 2.13, size.height * 1.83, size.width * 2.17,
        size.height * 1.83, size.width * 2.23, size.height * 1.82);
    path.cubicTo(size.width * 2.23, size.height * 1.82, size.width * 2.23,
        size.height * 1.82, size.width * 2.23, size.height * 1.82);
    canvas.drawPath(path, paint);

    // Path number rightarm
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 0.37, size.height * 1.06);
    path.cubicTo(size.width * 0.37, size.height * 1.06, size.width * 0.4,
        size.height * 1.05, size.width * 0.42, size.height * 1.03);
    path.cubicTo(size.width * 0.45, size.height, size.width * 0.46, size.height,
        size.width * 0.47, size.height);
    path.cubicTo(size.width * 0.48, size.height * 1.02, size.width * 0.47,
        size.height * 1.02, size.width * 0.46, size.height * 1.03);
    path.cubicTo(size.width * 0.44, size.height * 1.04, size.width * 0.43,
        size.height * 1.04, size.width * 0.44, size.height * 1.04);
    path.cubicTo(size.width * 0.45, size.height * 1.04, size.width * 0.48,
        size.height * 1.03, size.width / 2, size.height * 1.02);
    path.cubicTo(size.width * 0.51, size.height, size.width * 0.54, size.height,
        size.width * 0.56, size.height);
    path.cubicTo(size.width * 0.61, size.height * 0.98, size.width * 0.62,
        size.height * 0.97, size.width * 0.61, size.height * 0.95);
    path.cubicTo(size.width * 0.61, size.height * 0.93, size.width * 0.61,
        size.height * 0.93, size.width * 0.7, size.height * 0.88);
    path.cubicTo(size.width * 0.78, size.height * 0.83, size.width * 0.87,
        size.height * 0.76, size.width * 0.89, size.height * 0.73);
    path.cubicTo(size.width * 0.89, size.height * 0.73, size.width * 0.9,
        size.height * 0.72, size.width * 0.91, size.height * 0.71);
    path.cubicTo(size.width * 0.93, size.height * 0.7, size.width * 0.93,
        size.height * 0.68, size.width * 0.92, size.height * 0.67);
    path.cubicTo(size.width * 0.92, size.height * 0.67, size.width * 0.92,
        size.height * 0.66, size.width * 0.93, size.height * 0.66);
    path.cubicTo(size.width * 0.95, size.height * 0.65, size.width,
        size.height * 0.63, size.width, size.height * 0.62);
    path.cubicTo(size.width * 1.03, size.height * 0.6, size.width * 1.04,
        size.height * 0.59, size.width * 1.04, size.height * 0.56);
    path.cubicTo(size.width * 1.04, size.height * 0.53, size.width * 1.04,
        size.height * 0.51, size.width * 1.05, size.height * 0.51);
    path.cubicTo(size.width * 1.07, size.height * 0.49, size.width * 1.08,
        size.height * 0.45, size.width * 1.07, size.height * 0.43);
    path.cubicTo(size.width * 1.06, size.height * 0.41, size.width * 1.06,
        size.height * 0.4, size.width * 1.04, size.height * 0.4);
    path.cubicTo(size.width * 1.03, size.height * 0.4, size.width * 0.95,
        size.height * 0.41, size.width * 0.92, size.height * 0.42);
    path.cubicTo(size.width * 0.88, size.height * 0.43, size.width * 0.83,
        size.height * 0.44, size.width * 0.82, size.height * 0.46);
    path.cubicTo(size.width * 0.8, size.height * 0.47, size.width * 0.79,
        size.height * 0.51, size.width * 0.79, size.height * 0.53);
    path.cubicTo(size.width * 0.8, size.height * 0.53, size.width * 0.79,
        size.height * 0.54, size.width * 0.77, size.height * 0.54);
    path.cubicTo(size.width * 0.72, size.height * 0.57, size.width * 0.69,
        size.height * 0.59, size.width * 0.69, size.height * 0.62);
    path.cubicTo(size.width * 0.7, size.height * 0.63, size.width * 0.7,
        size.height * 0.63, size.width * 0.71, size.height * 0.64);
    path.cubicTo(size.width * 0.73, size.height * 0.65, size.width * 0.74,
        size.height * 0.65, size.width * 0.69, size.height * 0.66);
    path.cubicTo(size.width * 0.67, size.height * 0.67, size.width * 0.63,
        size.height * 0.69, size.width * 0.61, size.height * 0.71);
    path.cubicTo(size.width * 0.59, size.height * 0.73, size.width * 0.58,
        size.height * 0.74, size.width * 0.57, size.height * 0.77);
    path.cubicTo(size.width * 0.55, size.height * 0.81, size.width * 0.51,
        size.height * 0.85, size.width * 0.48, size.height * 0.87);
    path.cubicTo(size.width * 0.48, size.height * 0.87, size.width * 0.47,
        size.height * 0.87, size.width * 0.46, size.height * 0.88);
    path.cubicTo(size.width * 0.45, size.height * 0.89, size.width * 0.43,
        size.height * 0.9, size.width * 0.4, size.height * 0.91);
    path.cubicTo(size.width * 0.39, size.height * 0.91, size.width * 0.35,
        size.height * 0.92, size.width * 0.32, size.height * 0.93);
    path.cubicTo(size.width * 0.27, size.height * 0.95, size.width * 0.24,
        size.height * 0.95, size.width * 0.22, size.height * 0.96);
    path.cubicTo(size.width * 0.19, size.height * 0.96, size.width * 0.18,
        size.height * 0.96, size.width / 5, size.height * 0.97);
    path.cubicTo(size.width * 0.22, size.height * 0.97, size.width * 0.24,
        size.height * 0.97, size.width * 0.28, size.height * 0.97);
    path.cubicTo(size.width * 0.32, size.height * 0.96, size.width * 0.34,
        size.height * 0.96, size.width * 0.35, size.height * 0.97);
    path.cubicTo(size.width * 0.35, size.height * 0.97, size.width * 0.26,
        size.height * 1.02, size.width / 4, size.height * 1.02);
    path.cubicTo(size.width * 0.24, size.height * 1.02, size.width * 0.24,
        size.height * 1.03, size.width / 4, size.height * 1.04);
    path.cubicTo(size.width * 0.26, size.height * 1.04, size.width * 0.27,
        size.height * 1.03, size.width / 3, size.height);
    path.cubicTo(size.width * 0.38, size.height * 0.98, size.width * 0.39,
        size.height * 0.97, size.width * 0.39, size.height * 0.98);
    path.cubicTo(size.width * 0.39, size.height, size.width * 0.36, size.height,
        size.width * 0.32, size.height * 1.02);
    path.cubicTo(size.width * 0.3, size.height * 1.03, size.width * 0.27,
        size.height * 1.05, size.width * 0.27, size.height * 1.06);
    path.cubicTo(size.width * 0.27, size.height * 1.06, size.width * 0.29,
        size.height * 1.06, size.width * 0.3, size.height * 1.06);
    path.cubicTo(size.width * 0.31, size.height * 1.06, size.width * 0.34,
        size.height * 1.04, size.width * 0.36, size.height * 1.03);
    path.cubicTo(size.width * 0.41, size.height, size.width * 0.42, size.height,
        size.width * 0.43, size.height);
    path.cubicTo(size.width * 0.43, size.height, size.width * 0.42, size.height,
        size.width * 0.39, size.height * 1.03);
    path.cubicTo(size.width * 0.34, size.height * 1.06, size.width / 3,
        size.height * 1.07, size.width * 0.37, size.height * 1.06);
    path.cubicTo(size.width * 0.37, size.height * 1.06, size.width * 0.37,
        size.height * 1.06, size.width * 0.37, size.height * 1.06);
    canvas.drawPath(path, paint);

    // Path number leftarm
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 2.82, size.height * 1.06);
    path.cubicTo(size.width * 2.82, size.height * 1.06, size.width * 2.81,
        size.height * 1.05, size.width * 2.78, size.height * 1.03);
    path.cubicTo(size.width * 2.73, size.height, size.width * 2.72, size.height,
        size.width * 2.74, size.height);
    path.cubicTo(size.width * 2.75, size.height, size.width * 2.77, size.height,
        size.width * 2.82, size.height * 1.04);
    path.cubicTo(size.width * 2.86, size.height * 1.06, size.width * 2.87,
        size.height * 1.06, size.width * 2.89, size.height * 1.06);
    path.cubicTo(size.width * 2.9, size.height * 1.06, size.width * 2.89,
        size.height * 1.05, size.width * 2.87, size.height * 1.04);
    path.cubicTo(size.width * 2.85, size.height * 1.03, size.width * 2.82,
        size.height, size.width * 2.81, size.height);
    path.cubicTo(size.width * 2.78, size.height, size.width * 2.77,
        size.height * 0.98, size.width * 2.77, size.height * 0.98);
    path.cubicTo(size.width * 2.77, size.height * 0.98, size.width * 2.78,
        size.height * 0.98, size.width * 2.79, size.height * 0.98);
    path.cubicTo(size.width * 2.79, size.height * 0.98, size.width * 2.8,
        size.height * 0.98, size.width * 2.8, size.height);
    path.cubicTo(size.width * 2.8, size.height, size.width * 2.89,
        size.height * 1.03, size.width * 2.9, size.height * 1.04);
    path.cubicTo(size.width * 2.91, size.height * 1.04, size.width * 2.91,
        size.height * 1.04, size.width * 2.92, size.height * 1.03);
    path.cubicTo(size.width * 2.92, size.height * 1.03, size.width * 2.92,
        size.height * 1.03, size.width * 2.92, size.height * 1.03);
    path.cubicTo(size.width * 2.92, size.height * 1.03, size.width * 2.9,
        size.height, size.width * 2.86, size.height);
    path.cubicTo(size.width * 2.86, size.height, size.width * 2.81,
        size.height * 0.97, size.width * 2.81, size.height * 0.97);
    path.cubicTo(size.width * 2.81, size.height * 0.97, size.width * 2.82,
        size.height * 0.97, size.width * 2.82, size.height * 0.97);
    path.cubicTo(size.width * 2.84, size.height * 0.96, size.width * 2.85,
        size.height * 0.96, size.width * 2.88, size.height * 0.97);
    path.cubicTo(size.width * 2.92, size.height * 0.97, size.width * 2.95,
        size.height * 0.97, size.width * 2.96, size.height * 0.97);
    path.cubicTo(size.width * 2.97, size.height * 0.96, size.width * 2.97,
        size.height * 0.96, size.width * 2.97, size.height * 0.96);
    path.cubicTo(size.width * 2.97, size.height * 0.96, size.width * 2.96,
        size.height * 0.96, size.width * 2.94, size.height * 0.96);
    path.cubicTo(size.width * 2.92, size.height * 0.95, size.width * 2.89,
        size.height * 0.95, size.width * 2.83, size.height * 0.93);
    path.cubicTo(size.width * 2.78, size.height * 0.91, size.width * 2.75,
        size.height * 0.9, size.width * 2.75, size.height * 0.9);
    path.cubicTo(size.width * 2.75, size.height * 0.9, size.width * 2.75,
        size.height * 0.9, size.width * 2.74, size.height * 0.9);
    path.cubicTo(size.width * 2.74, size.height * 0.9, size.width * 2.73,
        size.height * 0.9, size.width * 2.73, size.height * 0.9);
    path.cubicTo(size.width * 2.73, size.height * 0.89, size.width * 2.72,
        size.height * 0.89, size.width * 2.71, size.height * 0.89);
    path.cubicTo(size.width * 2.67, size.height * 0.87, size.width * 2.61,
        size.height * 0.82, size.width * 2.6, size.height * 0.78);
    path.cubicTo(size.width * 2.58, size.height * 0.72, size.width * 2.55,
        size.height * 0.7, size.width * 2.47, size.height * 0.66);
    path.cubicTo(size.width * 2.47, size.height * 0.66, size.width * 2.43,
        size.height * 0.65, size.width * 2.43, size.height * 0.65);
    path.cubicTo(size.width * 2.43, size.height * 0.65, size.width * 2.45,
        size.height * 0.64, size.width * 2.45, size.height * 0.64);
    path.cubicTo(size.width * 2.47, size.height * 0.63, size.width * 2.47,
        size.height * 0.63, size.width * 2.47, size.height * 0.61);
    path.cubicTo(size.width * 2.47, size.height * 0.59, size.width * 2.44,
        size.height * 0.56, size.width * 2.39, size.height * 0.54);
    path.cubicTo(size.width * 2.37, size.height * 0.54, size.width * 2.37,
        size.height * 0.54, size.width * 2.37, size.height * 0.51);
    path.cubicTo(size.width * 2.37, size.height * 0.48, size.width * 2.36,
        size.height * 0.46, size.width * 2.34, size.height * 0.45);
    path.cubicTo(size.width * 2.31, size.height * 0.44, size.width * 2.24,
        size.height * 0.42, size.width * 2.19, size.height * 0.41);
    path.cubicTo(size.width * 2.17, size.height * 0.4, size.width * 2.14,
        size.height * 0.4, size.width * 2.13, size.height * 0.4);
    path.cubicTo(size.width * 2.1, size.height * 0.4, size.width * 2.1,
        size.height * 0.4, size.width * 2.09, size.height * 0.42);
    path.cubicTo(size.width * 2.08, size.height * 0.45, size.width * 2.09,
        size.height * 0.49, size.width * 2.11, size.height / 2);
    path.cubicTo(size.width * 2.12, size.height / 2, size.width * 2.12,
        size.height / 2, size.width * 2.12, size.height * 0.55);
    path.cubicTo(size.width * 2.12, size.height * 0.59, size.width * 2.12,
        size.height * 0.59, size.width * 2.14, size.height * 0.61);
    path.cubicTo(size.width * 2.16, size.height * 0.62, size.width * 2.19,
        size.height * 0.64, size.width * 2.22, size.height * 0.66);
    path.cubicTo(size.width * 2.24, size.height * 0.67, size.width * 2.24,
        size.height * 0.67, size.width * 2.24, size.height * 0.67);
    path.cubicTo(size.width * 2.22, size.height * 0.68, size.width * 2.23,
        size.height * 0.69, size.width * 2.24, size.height * 0.71);
    path.cubicTo(size.width * 2.25, size.height * 0.71, size.width * 2.26,
        size.height * 0.72, size.width * 2.27, size.height * 0.73);
    path.cubicTo(size.width * 2.31, size.height * 0.78, size.width * 2.38,
        size.height * 0.83, size.width * 2.47, size.height * 0.88);
    path.cubicTo(size.width * 2.56, size.height * 0.94, size.width * 2.55,
        size.height * 0.93, size.width * 2.55, size.height * 0.96);
    path.cubicTo(size.width * 2.55, size.height * 0.97, size.width * 2.55,
        size.height * 0.98, size.width * 2.6, size.height);
    path.cubicTo(size.width * 2.61, size.height, size.width * 2.64, size.height,
        size.width * 2.66, size.height * 1.02);
    path.cubicTo(size.width * 2.7, size.height * 1.04, size.width * 2.72,
        size.height * 1.05, size.width * 2.73, size.height * 1.04);
    path.cubicTo(size.width * 2.73, size.height * 1.04, size.width * 2.72,
        size.height * 1.04, size.width * 2.71, size.height * 1.03);
    path.cubicTo(size.width * 2.69, size.height * 1.02, size.width * 2.69,
        size.height, size.width * 2.7, size.height);
    path.cubicTo(size.width * 2.7, size.height, size.width * 2.72,
        size.height * 1.02, size.width * 2.74, size.height * 1.04);
    path.cubicTo(size.width * 2.79, size.height * 1.06, size.width * 2.8,
        size.height * 1.06, size.width * 2.82, size.height * 1.06);
    path.cubicTo(size.width * 2.82, size.height * 1.06, size.width * 2.82,
        size.height * 1.06, size.width * 2.82, size.height * 1.06);
    canvas.drawPath(path, paint);

    // Path number genitals
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.66, size.height * 0.93);
    path.cubicTo(size.width * 1.69, size.height * 0.92, size.width * 1.7,
        size.height * 0.92, size.width * 1.7, size.height * 0.9);
    path.cubicTo(size.width * 1.7, size.height * 0.89, size.width * 1.67,
        size.height * 0.87, size.width * 1.61, size.height * 0.87);
    path.cubicTo(size.width * 1.55, size.height * 0.86, size.width * 1.48,
        size.height * 0.88, size.width * 1.48, size.height * 0.9);
    path.cubicTo(size.width * 1.48, size.height * 0.92, size.width * 1.49,
        size.height * 0.92, size.width * 1.53, size.height * 0.93);
    path.cubicTo(size.width * 1.57, size.height * 0.93, size.width * 1.63,
        size.height * 0.93, size.width * 1.66, size.height * 0.93);
    path.cubicTo(size.width * 1.66, size.height * 0.93, size.width * 1.66,
        size.height * 0.93, size.width * 1.66, size.height * 0.93);
    canvas.drawPath(path, paint);

    // Path number lowertorso
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.45, size.height * 0.9);
    path.cubicTo(size.width * 1.45, size.height * 0.89, size.width * 1.46,
        size.height * 0.88, size.width * 1.47, size.height * 0.88);
    path.cubicTo(size.width * 1.49, size.height * 0.86, size.width * 1.54,
        size.height * 0.86, size.width * 1.59, size.height * 0.86);
    path.cubicTo(size.width * 1.68, size.height * 0.86, size.width * 1.73,
        size.height * 0.87, size.width * 1.73, size.height * 0.9);
    path.cubicTo(size.width * 1.73, size.height * 0.91, size.width * 1.74,
        size.height * 0.92, size.width * 1.74, size.height * 0.92);
    path.cubicTo(size.width * 1.74, size.height * 0.92, size.width * 1.77,
        size.height * 0.91, size.width * 1.8, size.height * 0.9);
    path.cubicTo(size.width * 1.89, size.height * 0.88, size.width * 1.94,
        size.height * 0.86, size.width * 2, size.height * 0.83);
    path.cubicTo(size.width * 2, size.height * 0.83, size.width * 2.03,
        size.height * 0.81, size.width * 2.03, size.height * 0.81);
    path.cubicTo(size.width * 2.03, size.height * 0.81, size.width * 2.03,
        size.height * 0.79, size.width * 2.03, size.height * 0.79);
    path.cubicTo(size.width * 2.03, size.height * 0.77, size.width * 2.02,
        size.height * 0.76, size.width * 2.02, size.height * 0.75);
    path.cubicTo(size.width * 2, size.height * 0.73, size.width * 2,
        size.height * 0.72, size.width * 2.02, size.height * 0.71);
    path.cubicTo(size.width * 2.03, size.height * 0.7, size.width * 2.04,
        size.height * 0.69, size.width * 2.04, size.height * 0.69);
    path.cubicTo(size.width * 2.04, size.height * 0.69, size.width * 2.04,
        size.height * 0.67, size.width * 2.04, size.height * 0.67);
    path.cubicTo(size.width * 2.04, size.height * 0.67, size.width * 2.02,
        size.height * 0.67, size.width * 2.02, size.height * 0.67);
    path.cubicTo(size.width * 2.01, size.height * 0.68, size.width * 1.95,
        size.height * 0.68, size.width * 1.89, size.height * 0.68);
    path.cubicTo(size.width * 1.8, size.height * 0.68, size.width * 1.76,
        size.height * 0.68, size.width * 1.59, size.height * 0.68);
    path.cubicTo(size.width * 1.39, size.height * 0.68, size.width * 1.32,
        size.height * 0.68, size.width * 1.15, size.height * 0.67);
    path.cubicTo(size.width * 1.15, size.height * 0.67, size.width * 1.12,
        size.height * 0.67, size.width * 1.12, size.height * 0.67);
    path.cubicTo(size.width * 1.12, size.height * 0.67, size.width * 1.12,
        size.height * 0.68, size.width * 1.12, size.height * 0.68);
    path.cubicTo(size.width * 1.12, size.height * 0.69, size.width * 1.13,
        size.height * 0.7, size.width * 1.14, size.height * 0.71);
    path.cubicTo(size.width * 1.16, size.height * 0.71, size.width * 1.15,
        size.height * 0.74, size.width * 1.14, size.height * 0.76);
    path.cubicTo(size.width * 1.12, size.height * 0.79, size.width * 1.13,
        size.height * 0.8, size.width * 1.17, size.height * 0.83);
    path.cubicTo(size.width * 1.23, size.height * 0.87, size.width * 1.34,
        size.height * 0.9, size.width * 1.43, size.height * 0.91);
    path.cubicTo(size.width * 1.44, size.height * 0.92, size.width * 1.45,
        size.height * 0.92, size.width * 1.45, size.height * 0.92);
    path.cubicTo(size.width * 1.45, size.height * 0.92, size.width * 1.45,
        size.height * 0.91, size.width * 1.45, size.height * 0.9);
    path.cubicTo(size.width * 1.45, size.height * 0.9, size.width * 1.45,
        size.height * 0.9, size.width * 1.45, size.height * 0.9);
    canvas.drawPath(path, paint);

    // Path number uppertorso
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.85, size.height * 0.67);
    path.cubicTo(size.width * 1.9, size.height * 0.67, size.width * 1.96,
        size.height * 0.67, size.width * 1.99, size.height * 0.67);
    path.cubicTo(size.width * 1.99, size.height * 0.67, size.width * 2.04,
        size.height * 0.67, size.width * 2.04, size.height * 0.67);
    path.cubicTo(size.width * 2.04, size.height * 0.67, size.width * 2.05,
        size.height * 0.66, size.width * 2.05, size.height * 0.66);
    path.cubicTo(size.width * 2.06, size.height * 0.64, size.width * 2.06,
        size.height * 0.59, size.width * 2.06, size.height * 0.57);
    path.cubicTo(size.width * 2.05, size.height * 0.56, size.width * 2.05,
        size.height * 0.55, size.width * 2.06, size.height * 0.53);
    path.cubicTo(size.width * 2.06, size.height * 0.52, size.width * 2.07,
        size.height / 2, size.width * 2.07, size.height / 2);
    path.cubicTo(size.width * 2.06, size.height * 0.47, size.width * 2.07,
        size.height * 0.41, size.width * 2.07, size.height * 0.41);
    path.cubicTo(size.width * 2.08, size.height * 0.4, size.width * 2.08,
        size.height * 0.4, size.width * 2.06, size.height * 0.4);
    path.cubicTo(size.width * 2.06, size.height * 0.4, size.width * 2.03,
        size.height * 0.4, size.width * 2.01, size.height * 0.39);
    path.cubicTo(size.width * 1.98, size.height * 0.39, size.width * 1.96,
        size.height * 0.39, size.width * 1.96, size.height * 0.39);
    path.cubicTo(size.width * 1.96, size.height * 0.39, size.width * 1.92,
        size.height * 0.38, size.width * 1.88, size.height * 0.37);
    path.cubicTo(size.width * 1.88, size.height * 0.37, size.width * 1.79,
        size.height * 0.36, size.width * 1.79, size.height * 0.36);
    path.cubicTo(size.width * 1.79, size.height * 0.36, size.width * 1.74,
        size.height * 0.37, size.width * 1.74, size.height * 0.37);
    path.cubicTo(size.width * 1.67, size.height * 0.37, size.width * 1.48,
        size.height * 0.37, size.width * 1.42, size.height * 0.37);
    path.cubicTo(size.width * 1.42, size.height * 0.37, size.width * 1.37,
        size.height * 0.36, size.width * 1.37, size.height * 0.36);
    path.cubicTo(size.width * 1.37, size.height * 0.36, size.width * 1.27,
        size.height * 0.38, size.width * 1.27, size.height * 0.38);
    path.cubicTo(size.width * 1.21, size.height * 0.38, size.width * 1.15,
        size.height * 0.39, size.width * 1.14, size.height * 0.39);
    path.cubicTo(size.width * 1.12, size.height * 0.4, size.width * 1.1,
        size.height * 0.4, size.width * 1.1, size.height * 0.4);
    path.cubicTo(size.width * 1.1, size.height * 0.4, size.width * 1.08,
        size.height * 0.4, size.width * 1.08, size.height * 0.4);
    path.cubicTo(size.width * 1.08, size.height * 0.4, size.width * 1.09,
        size.height * 0.41, size.width * 1.09, size.height * 0.41);
    path.cubicTo(size.width * 1.11, size.height * 0.43, size.width * 1.11,
        size.height * 0.48, size.width * 1.08, size.height / 2);
    path.cubicTo(size.width * 1.07, size.height * 0.51, size.width * 1.07,
        size.height * 0.51, size.width * 1.09, size.height * 0.52);
    path.cubicTo(size.width * 1.12, size.height * 0.52, size.width * 1.12,
        size.height * 0.52, size.width * 1.11, size.height * 0.59);
    path.cubicTo(size.width * 1.1, size.height * 0.61, size.width * 1.1,
        size.height * 0.63, size.width * 1.11, size.height * 0.64);
    path.cubicTo(size.width * 1.11, size.height * 0.65, size.width * 1.12,
        size.height * 0.66, size.width * 1.12, size.height * 0.66);
    path.cubicTo(size.width * 1.13, size.height * 0.67, size.width * 1.31,
        size.height * 0.67, size.width * 1.44, size.height * 0.68);
    path.cubicTo(size.width * 1.51, size.height * 0.68, size.width * 1.77,
        size.height * 0.68, size.width * 1.85, size.height * 0.67);
    path.cubicTo(size.width * 1.85, size.height * 0.67, size.width * 1.85,
        size.height * 0.67, size.width * 1.85, size.height * 0.67);
    canvas.drawPath(path, paint);

    // Path number head
    paint.color = Color(0xff4f81bd).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.72, size.height * 0.36);
    path.cubicTo(size.width * 1.74, size.height * 0.36, size.width * 1.76,
        size.height * 0.36, size.width * 1.76, size.height * 0.36);
    path.cubicTo(size.width * 1.77, size.height * 0.35, size.width * 1.77,
        size.height * 0.35, size.width * 1.77, size.height / 3);
    path.cubicTo(size.width * 1.76, size.height * 0.32, size.width * 1.77,
        size.height * 0.31, size.width * 1.77, size.height * 0.31);
    path.cubicTo(size.width * 1.78, size.height * 0.3, size.width * 1.79,
        size.height * 0.29, size.width * 1.79, size.height * 0.29);
    path.cubicTo(size.width * 1.8, size.height * 0.26, size.width * 1.8,
        size.height * 0.26, size.width * 1.82, size.height * 0.26);
    path.cubicTo(size.width * 1.84, size.height * 0.26, size.width * 1.84,
        size.height * 0.26, size.width * 1.86, size.height / 4);
    path.cubicTo(size.width * 1.87, size.height * 0.24, size.width * 1.88,
        size.height * 0.23, size.width * 1.88, size.height * 0.23);
    path.cubicTo(size.width * 1.88, size.height * 0.22, size.width * 1.88,
        size.height * 0.22, size.width * 1.85, size.height * 0.22);
    path.cubicTo(size.width * 1.85, size.height * 0.22, size.width * 1.82,
        size.height / 5, size.width * 1.82, size.height / 5);
    path.cubicTo(size.width * 1.82, size.height / 5, size.width * 1.82,
        size.height / 5, size.width * 1.82, size.height / 5);
    path.cubicTo(size.width * 1.82, size.height * 0.15, size.width * 1.75,
        size.height * 0.12, size.width * 1.62, size.height * 0.12);
    path.cubicTo(size.width * 1.53, size.height * 0.11, size.width * 1.42,
        size.height * 0.13, size.width * 1.37, size.height * 0.15);
    path.cubicTo(size.width * 1.35, size.height * 0.16, size.width * 1.34,
        size.height * 0.19, size.width * 1.34, size.height / 5);
    path.cubicTo(size.width * 1.34, size.height / 5, size.width * 1.33,
        size.height / 5, size.width * 1.32, size.height / 5);
    path.cubicTo(size.width * 1.27, size.height * 0.22, size.width * 1.27,
        size.height * 0.22, size.width * 1.3, size.height / 4);
    path.cubicTo(size.width * 1.32, size.height * 0.26, size.width * 1.33,
        size.height * 0.26, size.width * 1.35, size.height * 0.26);
    path.cubicTo(size.width * 1.36, size.height * 0.26, size.width * 1.37,
        size.height * 0.26, size.width * 1.37, size.height * 0.26);
    path.cubicTo(size.width * 1.37, size.height * 0.28, size.width * 1.39,
        size.height * 0.31, size.width * 1.4, size.height * 0.31);
    path.cubicTo(size.width * 1.4, size.height * 0.31, size.width * 1.4,
        size.height * 0.31, size.width * 1.4, size.height * 0.32);
    path.cubicTo(size.width * 1.4, size.height * 0.32, size.width * 1.4,
        size.height / 3, size.width * 1.4, size.height * 0.34);
    path.cubicTo(size.width * 1.4, size.height * 0.34, size.width * 1.39,
        size.height * 0.36, size.width * 1.39, size.height * 0.36);
    path.cubicTo(size.width * 1.39, size.height * 0.36, size.width * 1.42,
        size.height * 0.36, size.width * 1.42, size.height * 0.36);
    path.cubicTo(size.width * 1.49, size.height * 0.36, size.width * 1.63,
        size.height * 0.36, size.width * 1.72, size.height * 0.36);
    path.cubicTo(size.width * 1.72, size.height * 0.36, size.width * 1.72,
        size.height * 0.36, size.width * 1.72, size.height * 0.36);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
