import 'package:flutter/material.dart';
import 'package:testapp/core/elements/bottombar.dart';
import 'package:testapp/features/Screens/main_screen.dart';
import 'package:testapp/features/Screens/message_screen.dart';
import 'package:testapp/features/Screens/myservices_screen.dart';
import 'package:testapp/features/Screens/profile_screen.dart';
import 'package:testapp/features/Screens/whatsnew_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String apptext = 'home';

  int currenPage = 0;

  Color activecolor = Colors.pink;

  PageController pageController = PageController();

  List<Widget> pages = const [
    MainScreen(),
    Whatsnew_screen(),
    MyserviceScreen(),
    MessageScreen(),
    ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: pageController,
        onPageChanged: (index){
          currenPage = index;
          setState(() {
          });
        },
        itemCount: pages.length,
        itemBuilder: (BuildContext context, int position){
          return pages[position];
        },
      ),
      bottomNavigationBar: Bottom_bar(
        inactiveIconColor: Colors.grey,
          circleColor: activecolor,
          onChange: (position){
            currenPage = position;
            setState(() {
              if(position == 0){
                apptext = 'home';
                activecolor = Colors.pink;
                pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
              }else if(position == 1){
                pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                apptext = 'WhatsNew';
                activecolor = Colors.deepOrangeAccent;
              }else if(position == 2){
                pageController.animateToPage(2, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                activecolor = Colors.green;
                apptext = 'MyServices';
              }else if (position == 3){
                pageController.animateToPage(3, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                activecolor = Colors.blueAccent;
                apptext = 'MessagePage';
              }else {
                activecolor = Colors.green;
                pageController.animateToPage(4, duration: Duration(milliseconds: 300), curve: Curves.easeIn);
                apptext = 'ProfilePage';
              }
            });
          },
          bottombaritems: [
            BottombarItemData(iconData: Icons.home),
            BottombarItemData(iconData: Icons.directions),
            BottombarItemData(iconData: Icons.calendar_month_rounded),
            BottombarItemData(iconData: Icons.wordpress_rounded),
            BottombarItemData(iconData: Icons.person)
          ]
      )
    );
  }
}
