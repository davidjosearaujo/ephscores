import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Anterior extends StatefulWidget {
  const Anterior();

  @override
  _AnteriorState createState() => _AnteriorState();
}

class _AnteriorState extends State<Anterior> {
  @override
  Widget build(BuildContext context) {
    return Column(
		  children:[
			  SvgPicture.asset("assets/Front/head_front.svg"),
		  ]
	  );
  }
}