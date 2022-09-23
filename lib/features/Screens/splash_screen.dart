import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:testapp/features/Screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{

  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
            'assets/lottie/hacker-found-solution.json',
          animate: true,
          onLoaded: (composition){
              controller
                ..duration = composition.duration
                  ..forward().whenComplete(() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())));
          }
        ),
      ),
    );
  }
}
