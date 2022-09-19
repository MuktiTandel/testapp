import 'package:flutter/material.dart';
import 'package:testapp/core/constant.dart';
import 'package:testapp/core/elements/bottombaritem.dart';
import 'package:testapp/core/elements/customcolor.dart';

class Bottom_bar extends StatefulWidget {
  const Bottom_bar({
    Key? key,
    required this.onChange,
    this.activeIconColor,
    this.backgroundColor,
    required this.bottombaritems,
    this.circleColor,
    this.inactiveIconColor,
    this.intialselect = 0,
  }) : super(key: key);

  final Function(int position) onChange;
  final Color? circleColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;
  final Color? backgroundColor;
  final List<BottombarItemData> bottombaritems;
  final int intialselect;

  @override
  State<Bottom_bar> createState() => _Bottom_barState();
}

class _Bottom_barState extends State<Bottom_bar> with TickerProviderStateMixin, RouteAware{

  IconData nextIcon = Icons.search;
  IconData activeIcon = Icons.search;

  int currentSelect = 0;
  double circleAlignX = 0;
  double circleIconOpacity = 1;

  late Color activeIconColor;
  late Color inactiveIconColor;
  late Color backgroundColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    activeIcon = widget.bottombaritems[currentSelect].iconData;

    activeIconColor = widget.activeIconColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.white);

    backgroundColor = widget.backgroundColor ?? (Theme.of(context).brightness == Brightness.dark ? CustomColor.black : Colors.white);

    inactiveIconColor = widget.inactiveIconColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor);

  }

  @override
  void initState() {
    super.initState();

    setSelected(widget.bottombaritems[widget.intialselect].key);
  }

  void setSelected(UniqueKey uniqueKey) {

    int selected = widget.bottombaritems.indexWhere((element) => element.key == uniqueKey);

    if(mounted){
      setState(() {
        currentSelect = selected;
        circleAlignX = -1 + (2 / (widget.bottombaritems.length - 1) * selected);
        nextIcon = widget.bottombaritems[selected].iconData;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Container(
     height: 80,
      child: Stack(
        clipBehavior: Clip.none, alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            height: Constant.bar_height,
            decoration: BoxDecoration(color: backgroundColor, boxShadow: [
              BoxShadow(
                  color: Colors.black12, offset: Offset(0, -1), blurRadius: 8)
            ]),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: widget.bottombaritems
                  .map((e) => Bottombar_Item(
                  uniqueKey: e.key,
                  iconData: e.iconData,
                  icon_color: inactiveIconColor,
                  ontap: (key) {
                    int selected = widget.bottombaritems.indexWhere((element) => element.key == key);
                    widget.onChange(selected);
                    setSelected(key);
                    initAnimationAndStart(circleAlignX, 1);
                  },
                  selected: e.key == widget.bottombaritems[currentSelect].key
              )).toList()
            ),
          ),
          Container(
            child: AnimatedAlign(
              duration: Duration(milliseconds: Constant.animation_duration),
              curve: Curves.easeOut,
              alignment: Alignment(circleAlignX, 1.015),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: FractionallySizedBox(
                  widthFactor: 1 / widget.bottombaritems.length,
                  child: GestureDetector(
                    onTap: widget.bottombaritems[currentSelect].onClick as void
                    Function()?,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        SizedBox(
                          height: Constant.circle_size + Constant.circle_border + Constant.shadow_allowance,
                          width: Constant.circle_size + Constant.circle_border + Constant.shadow_allowance,
                          child: Container(
                            child: Center(
                              child: Container(
                                  width: Constant.circle_size + Constant.circle_border,
                                  height: Constant.circle_size + Constant.circle_border,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8)
                                      ])),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Constant.circle_size,
                          width: Constant.circle_size,
                          child: Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: widget.circleColor),
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: AnimatedOpacity(
                                duration:
                                Duration(milliseconds: Constant.animation_duration ~/ 5),
                                opacity: circleIconOpacity,
                                child: Icon(
                                  activeIcon,
                                  color: activeIconColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void initAnimationAndStart(double from, double to) {

    circleIconOpacity = 0;

    Future.delayed(Duration(milliseconds: Constant.animation_duration ~/ 5), () {
      setState(() {
        activeIcon = nextIcon;
      });
    }).then((value) {
      Future.delayed(Duration(milliseconds: (Constant.animation_duration ~/ 5 * 3)), (){
        setState(() {
          circleIconOpacity = 1;
        });
      });
    });
  }
}

class BottombarItemData{

  BottombarItemData({
    required this.iconData,
    this.onClick,
  });

  IconData iconData;
  Function? onClick;
  final UniqueKey key = UniqueKey();
}
