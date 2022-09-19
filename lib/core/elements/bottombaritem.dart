import 'package:flutter/material.dart';
import 'package:testapp/core/constant.dart';

class Bottombar_Item extends StatelessWidget {
  const Bottombar_Item({
    Key? key,
    required this.uniqueKey,
    required this.iconData,
    required this.icon_color,
    required this.ontap,
    required this.selected
  }) : super(key: key);

  final UniqueKey uniqueKey;
  final IconData iconData;
  final bool selected;
  final Function(UniqueKey key) ontap;
  final Color icon_color;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: AnimatedAlign(
        alignment: Alignment(0, selected ? Constant.icon_unselect : Constant.IsSelect),
        duration: Duration(milliseconds: Constant.animation_duration),
      curve: Curves.easeIn,
      child: AnimatedOpacity(
          opacity: selected ? Constant.IsUnselect : Constant.IsSelect,
          duration: Duration(
            milliseconds: Constant.animation_duration
          ),
        child: IconButton(
            onPressed: (){
              ontap(uniqueKey);
            },
            icon: Icon(
                iconData,
              color: icon_color,
              size: 30,
            )
        ),
      ),
    )
    );
  }
}
