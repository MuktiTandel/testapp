import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:testapp/core/elements/draw_circle.dart';

class Whatsnew_screen extends StatefulWidget {
  const Whatsnew_screen({Key? key}) : super(key: key);

  @override
  State<Whatsnew_screen> createState() => _Whatsnew_screenState();
}

class _Whatsnew_screenState extends State<Whatsnew_screen> with SingleTickerProviderStateMixin {

  late AnimationController animationController;

  late Animation<double> animation;

  int x = 0;
  int y = 30;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this,
      duration: Duration(seconds: 4)
    )..repeat();

    Tween<double> rotationTween = Tween(begin: -pi, end: pi);

    animation = rotationTween.animate(animationController)
      ..addListener(() {
        setState(() {
        });
      })..addStatusListener((status) {
        if(status == AnimationStatus.completed){
          animationController.repeat();
        } else if(status == animationController.isDismissed){
          animationController.forward();
        }
      });

    animationController.addListener(() {
      setState(() {

      });
    });

    timer = Timer.periodic(Duration(seconds:  5), (timer) {
      change_eye_position();
    });

  }

  void change_eye_position(){
    Future.delayed(Duration(seconds: 1), (){
      x = 0;
      y = 40;
    });
    Future.delayed(Duration(seconds: 2), (){
      x = -5;
      y = 30;
    });
    Future.delayed(Duration(seconds: 3), (){
      x = 5;
      y = 20;
    });
    Future.delayed(Duration(seconds: 4), (){
      x = 5;
      y = 30;
    });
    setState(() {
    });
  }



  @override
  void dispose() {
    animationController.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsNew'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Stack(
            children: [
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.width),
                painter: DrawCircle(
                    radius: 100,
                    color: Colors.yellow,
                    controller: animationController,
                  x: x,
                  y: y
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

