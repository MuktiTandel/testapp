import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:testapp/core/constant.dart';

typedef OnMenuStateChange = void Function(bool IsOpen);

typedef SearchMatch = bool Function(
    DropdownMenuItem item,
    String searchText);

SearchMatch defaultSearchMatch = (item, searchText){
  return item.value.toString().toLowerCase().contains(searchText.toLowerCase());
};

class DropdownMenuPainter extends CustomPainter {

  final Color? color;
  final int? elevation;
  final int? selectedIndex;
  final Animation<double> resize;
  final double itemHeight;
  final BoxDecoration? dropdwonDecoration;

  final BoxPainter painter;

  DropdownMenuPainter({
    this.color,
    this.dropdwonDecoration,
    this.elevation,
    required this.itemHeight,
    required this.resize,
    this.selectedIndex,
  }) : painter = dropdwonDecoration?.copyWith(
    color: dropdwonDecoration.color ?? color,
    boxShadow: dropdwonDecoration.boxShadow ?? kElevationToShadow[elevation]
  ).createBoxPainter() ?? BoxDecoration(
    color: color,
    borderRadius: BorderRadius.all(Radius.circular(2)),
    boxShadow: kElevationToShadow[elevation]
  ).createBoxPainter(), super(repaint: resize);

  @override
  void paint(Canvas canvas, Size size) {

    final Tween<double> top = Tween<double>(
      begin: 0,
      end: 0
    );

    final Tween<double> bottom = Tween<double>(
      begin: clampDouble(
          top.begin! + itemHeight,
          min(itemHeight, size.height),
          size.height
      ),
      end: size.height
    );

    final Rect rect = Rect.fromLTRB(0.0, top.evaluate(resize), size.width, bottom.evaluate(resize));

    painter.paint(canvas, rect.topLeft, ImageConfiguration(size: rect.size));

  }

  @override
  bool shouldRepaint(DropdownMenuPainter oldDelegate) {
    return oldDelegate.color != color ||
      oldDelegate.elevation != elevation ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.dropdwonDecoration != dropdwonDecoration ||
      oldDelegate.itemHeight != itemHeight ||
      oldDelegate.resize != resize;
  }

}

class DropdownMenuItemButton<T> extends StatefulWidget {
  const DropdownMenuItemButton({
    Key? key,
    required this.constraints,
    this.itemHeight,
    required this.route,
    required this.buttonRect,
    required this.enableFeedback,
    required this.itemIndex,
    this.itemsHeights,
    this.padding
  }) : super(key: key);

  final DropdwonRoute<T> route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final int itemIndex;
  final bool enableFeedback;
  final List<double>? itemsHeights;
  final double? itemHeight;

  @override
  State<DropdownMenuItemButton<T>> createState() => _DropdownMenuItemButtonState<T>();
}

class _DropdownMenuItemButtonState<T> extends State<DropdownMenuItemButton<T>> {

  void handleFocusChange(bool focus) {

    final bool inTraditionalMode;

    switch(FocusManager.instance.highlightMode){
      case FocusHighlightMode.touch:
        inTraditionalMode = false;
        break;
      case FocusHighlightMode.traditional:
        inTraditionalMode = true;
        break;
    }

    if( focus && inTraditionalMode){
      final MenuLimits menuLimits = widget.route.getMenuLimits(
        widget.buttonRect,
        widget.constraints.maxHeight,
        widget.itemIndex,
      );
      widget.route.scrollController!.animateTo(
        menuLimits.scrollOffset,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 100),
      );
    }
  }

  void handleOnTap() {
    final DropdownMenuItem<T> dropdownMenuItem = widget.route.items[widget.itemIndex].item!;

    dropdownMenuItem.onTap?.call();

    Navigator.pop(
      context,
      DropdwonRouteResult<T>(dropdownMenuItem.value),
    );
  }

  static const Map<ShortcutActivator, Intent> _webShortcuts =
  <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowDown):
    DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp):
    DirectionalFocusIntent(TraversalDirection.up),
  };

  @override
  Widget build(BuildContext context) {

    final DropdownMenuItem dropdownMenuItem =
    widget.route.items[widget.itemIndex].item!;
    final double unit = 0.5 / (widget.route.items.length + 1.5);
    final double start =
    clampDouble(0.5 + (widget.itemIndex + 1) * unit, 0.0, 1.0);
    final double end = clampDouble(start + 1.5 * unit, 0.0, 1.0);
    final CurvedAnimation opacity = CurvedAnimation(
        parent: widget.route.animation!, curve: Interval(start, end));

    Widget child = Container(
      padding: widget.padding,
      height: widget.itemsHeights == null
          ? widget.route.itemHeight
          : widget.itemsHeights![widget.itemIndex],
      child: widget.route.items[widget.itemIndex],
    );

    if (dropdownMenuItem.enabled) {
      final _isSelectedItem = !widget.route.isNoSelectedItem &&
          widget.itemIndex == widget.route.selectedIndex;
      child = InkWell(
        autofocus: _isSelectedItem,
        enableFeedback: widget.enableFeedback,
        onTap: handleOnTap,
        onFocusChange: handleFocusChange,
        child: Container(
          color:
          _isSelectedItem ? widget.route.selectedItemHighlightColor : null,
          child: child,
        ),
      );
    }
    child = FadeTransition(opacity: opacity, child: child);
    if (kIsWeb && dropdownMenuItem.enabled) {
      child = Shortcuts(
        shortcuts: _webShortcuts,
        child: child,
      );
    }
    return child;
  }
}

class DropdwonMenu<T> extends StatefulWidget {
  const DropdwonMenu({
    Key? key,
    required this.constraints,
    required this.route,
    this.padding,
    required this.enableFeedback,
    this.dropdownDecoration,
    this.dropdownPadding,
    this.dropdownScrollPadding,
    required this.offset,
    this.scrollbarAlwaysShow,
    this.scrollbarRadius,
    this.scrollbarThickness,
    this.searchController,
    this.searchInnerWidget,
    this.searchMatch,
    this.customItemsHeights,
    required this.itemHeight,
    required this.buttonRect
  }) : super(key: key);

  final DropdwonRoute<T> route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final bool enableFeedback;
  final double itemHeight;
  final BoxDecoration? dropdownDecoration;
  final EdgeInsetsGeometry? dropdownPadding;
  final EdgeInsetsGeometry? dropdownScrollPadding;
  final Radius? scrollbarRadius;
  final double? scrollbarThickness;
  final bool? scrollbarAlwaysShow;
  final Offset offset;
  final List<double>? customItemsHeights;
  final TextEditingController? searchController;
  final Widget? searchInnerWidget;
  final SearchMatch? searchMatch;

  @override
  State<DropdwonMenu<T>> createState() => _DropdwonMenuState<T>();
}

class _DropdwonMenuState<T> extends State<DropdwonMenu<T>> {

  late CurvedAnimation fadeOpacity;
  late CurvedAnimation resize;
  late List<Widget> children;
  late SearchMatch searchMatch;

  @override
  void initState() {
    super.initState();

    fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0),
    );

    resize = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Threshold(0.0),
    );

    if (widget.searchController == null) {
      children = <Widget>[
        for (int index = 0; index < widget.route.items.length; ++index)
          DropdownMenuItemButton<T>(
            route: widget.route,
            padding: widget.padding,
            buttonRect: widget.buttonRect,
            constraints: widget.constraints,
            itemIndex: index,
            enableFeedback: widget.enableFeedback,
            itemsHeights: widget.customItemsHeights,
          ),
      ];
    } else {
      searchMatch = widget.searchMatch ?? defaultSearchMatch;
      children = getSearchItems();
      widget.searchController?.addListener(updateSearchItems);
    }
  }

  void updateSearchItems() {
    children = getSearchItems();
    setState(() {});
  }

  List<Widget> getSearchItems() {
    return <Widget>[
      for (int index = 0; index < widget.route.items.length; ++index)
        if (searchMatch(
            widget.route.items[index].item!, widget.searchController!.text))
          DropdownMenuItemButton<T>(
            route: widget.route,
            padding: widget.padding,
            buttonRect: widget.buttonRect,
            constraints: widget.constraints,
            itemIndex: index,
            enableFeedback: widget.enableFeedback,
            itemsHeights: widget.customItemsHeights,
          ),
    ];
  }

  @override
  void dispose() {
    fadeOpacity.dispose();
    resize.dispose();
    widget.searchController?.removeListener(updateSearchItems);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
    MaterialLocalizations.of(context);
    final DropdwonRoute<T> route = widget.route;

    return FadeTransition(
      opacity: fadeOpacity,
      child: CustomPaint(
        painter: DropdownMenuPainter(
          color: Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndex,
          resize: resize,
          itemHeight: widget.itemHeight,
          dropdwonDecoration: widget.dropdownDecoration,
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: localizations.popupMenuLabel,
          child: ClipRRect(
            clipBehavior: widget.dropdownDecoration?.borderRadius != null
                ? Clip.antiAlias
                : Clip.none,
            borderRadius: widget.dropdownDecoration?.borderRadius
                ?.resolve(Directionality.of(context)) ??
                BorderRadius.zero,
            child: Material(
              type: MaterialType.transparency,
              textStyle: route.style,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.searchInnerWidget != null)
                    widget.searchInnerWidget!,
                  Flexible(
                    child: Padding(
                      padding: widget.dropdownScrollPadding ?? EdgeInsets.zero,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          scrollbars: false,
                          overscroll: false,
                          physics: const ClampingScrollPhysics(),
                          platform: Theme.of(context).platform,
                        ),
                        child: PrimaryScrollController(
                          controller: widget.route.scrollController!,
                          child: Scrollbar(
                            radius: widget.scrollbarRadius,
                            thickness: widget.scrollbarThickness,
                            thumbVisibility: widget.scrollbarAlwaysShow,
                            child: ListView(
                              primary: true,
                              padding: widget.dropdownPadding ??
                                  kMaterialListPadding,
                              shrinkWrap: true,
                              children: children,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DropdwonMenuRouteLayout<T> extends SingleChildLayoutDelegate {

  final Rect buttonRect;
  final DropdwonRoute<T> route;
  final TextDirection? textDirection;
  final double itemHeight;
  final double? itemWidth;
  final Offset offset;

  DropdwonMenuRouteLayout({
    required this.buttonRect,
    required this.itemHeight,
    required this.offset,
    required this.route,
    this.itemWidth,
    this.textDirection
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight = max(0.0, constraints.maxHeight - 2 * itemHeight);
    if (route.menuMaxHeight != null && route.menuMaxHeight! <= maxHeight) {
      maxHeight = route.menuMaxHeight!;
    }
    final double width =
        itemWidth ?? min(constraints.maxWidth, buttonRect.width);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final MenuLimits menuLimits =
    route.getMenuLimits(buttonRect, size.height, route.selectedIndex);

    assert(() {
      final Rect container = Offset.zero & size;
      if (container.intersect(buttonRect) == buttonRect) {
        assert(menuLimits.top >= 0.0);
        assert(menuLimits.top + menuLimits.height <= size.height);
      }
      return true;
    }());
    assert(textDirection != null);
    final double left;
    switch (textDirection!) {
      case TextDirection.rtl:
        left = clampDouble(buttonRect.right + offset.dx, 0.0, size.width) -
            childSize.width;
        break;
      case TextDirection.ltr:
        left = clampDouble(
            buttonRect.left + offset.dx, 0.0, size.width - childSize.width);
        break;
    }

    return Offset(left, menuLimits.top);
  }

  @override
  bool shouldRelayout(DropdwonMenuRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        textDirection != oldDelegate.textDirection;
  }
}

@immutable
class DropdwonRouteResult<T> {

  final T? result;

  DropdwonRouteResult(this.result);

  @override
  bool operator ==(Object other){
    return other is DropdwonRouteResult<T> && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;

}

class MenuLimits {

  final double top;
  final double bottom;
  final double height;
  final double scrollOffset;

  MenuLimits(
    this.top,
      this.bottom,
      this.height,
      this.scrollOffset
  );
}

class DropdwonRoute<T> extends PopupRoute<DropdwonRouteResult<T>> {

  final List<MenuItem<T>> items;
  final EdgeInsetsGeometry padding;
  final ValueNotifier<Rect?> buttonRect;
  final int selectedIndex;
  final bool isNoSelectedItem;
  final Color? selectedItemHighlightColor;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle style;
  final bool enableFeedback;
  final double itemHeight;
  final double? itemWidth;
  final double? menuMaxHeight;
  final BoxDecoration? dropdownDecoration;
  final EdgeInsetsGeometry? dropdownPadding;
  final EdgeInsetsGeometry? dropdownScrollPadding;
  final Radius? scrollbarRadius;
  final double? scrollbarThickness;
  final bool? scrollbarAlwaysShow;
  final Offset offset;
  final bool showAboveButton;
  final List<double>? customItemsHeights;
  final TextEditingController? searchController;
  final Widget? searchInnerWidget;
  final SearchMatch? searchMatch;

  final List<double> itemHeights;
  ScrollController? scrollController;

  DropdwonRoute({
   required this.padding,
    required this.enableFeedback,
    required this.buttonRect,
    required this.itemHeight,
    required this.selectedIndex,
    required this.elevation,
    required this.capturedThemes,
    this.customItemsHeights,
    this.dropdownDecoration,
    this.dropdownPadding,
    this.dropdownScrollPadding,
    required this.isNoSelectedItem,
    required this.items,
    this.itemWidth,
    this.menuMaxHeight,
    required this.offset,
    this.scrollbarAlwaysShow,
    this.scrollbarRadius,
    this.scrollbarThickness,
    this.searchController,
    this.searchInnerWidget,
    this.searchMatch,
    this.selectedItemHighlightColor,
    required this.showAboveButton,
    required this.style,
    required this.barrierColor,
    required this.barrierDismissible,
    required this.barrierLabel
  }) : itemHeights = customItemsHeights ?? List<double>.filled(items.length, itemHeight);

  @override
  final Color? barrierColor;

  @override
  final bool  barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints){
          return ValueListenableBuilder<Rect?>(
              valueListenable: buttonRect,
              builder: (context, rect, _){
                return DropdwonRoutePage(
                  route: this,
                  constraints: constraints,
                  items: items,
                  padding: padding,
                  buttonRect: rect!,
                  selectedIndex: selectedIndex,
                  elevation: elevation,
                  capturedThemes: capturedThemes,
                  style: style,
                  enableFeedback: enableFeedback,
                  dropdownDecoration: dropdownDecoration,
                  dropdownPadding: dropdownPadding,
                  dropdownScrollPadding: dropdownScrollPadding,
                  menuMaxHeight: menuMaxHeight,
                  itemHeight: itemHeight,
                  itemWidth: itemWidth,
                  scrollbarRadius: scrollbarRadius,
                  scrollbarThickness: scrollbarThickness,
                  scrollbarAlwaysShow: scrollbarAlwaysShow,
                  offset: offset,
                  customItemsHeights: customItemsHeights,
                  searchController: searchController,
                  searchInnerWidget: searchInnerWidget,
                  searchMatch: searchMatch,
                );
              }
          );
        }
        );
  }

  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }

  double getItemOffset(int index, double paddingTop) {
    double offset = paddingTop;
    if (items.isNotEmpty && index > 0) {
      assert(items.length == itemHeights.length);
      offset += itemHeights
          .sublist(0, index)
          .reduce((double total, double height) => total + height);
    }
    return offset;
  }

  MenuLimits getMenuLimits(
      Rect buttonRect, double availableHeight, int index) {
    double computedMaxHeight = availableHeight - 2.0 * itemHeight;
    if (menuMaxHeight != null) {
      computedMaxHeight = min(computedMaxHeight, menuMaxHeight!);
    }
    final double buttonTop = buttonRect.top;
    final double buttonBottom = min(buttonRect.bottom, availableHeight);
    final double selectedItemOffset = getItemOffset(
      index,
      dropdownPadding != null
          ? dropdownPadding!.resolve(null).top
          : kMaterialListPadding.top,
    );

    final double topLimit = min(itemHeight, buttonTop);
    final double bottomLimit = max(availableHeight, buttonBottom);
    double menuTop =
    showAboveButton ? buttonTop - offset.dy : buttonBottom - offset.dy;
    double preferredMenuHeight =
        dropdownPadding?.vertical ?? kMaterialListPadding.vertical;
    if (items.isNotEmpty) {
      preferredMenuHeight +=
          itemHeights.reduce((double total, double height) => total + height);
    }

    final double menuHeight = min(computedMaxHeight, preferredMenuHeight);
    double menuBottom = menuTop + menuHeight;

    if (menuTop < topLimit) {
      menuTop = min(buttonTop, topLimit);
      menuBottom = menuTop + menuHeight;
    }

    if (menuBottom > bottomLimit) {
      menuBottom = max(buttonBottom, bottomLimit);
      menuTop = menuBottom - menuHeight;
    }

    if (menuBottom - itemHeights[selectedIndex] / 2.0 <
        buttonBottom - buttonRect.height / 2.0) {
      menuBottom = max(buttonBottom, bottomLimit);
      menuTop = menuBottom - menuHeight;
    }

    double scrollOffset = 0;
    if (preferredMenuHeight > computedMaxHeight) {
      scrollOffset = max(
          0.0,
          selectedItemOffset -
              (menuHeight / 2) +
              (itemHeights[selectedIndex] / 2));
      scrollOffset = min(scrollOffset, preferredMenuHeight - menuHeight);
    }

    assert((menuBottom - menuTop - menuHeight).abs() < precisionErrorTolerance);
    return MenuLimits(menuTop, menuBottom, menuHeight, scrollOffset);
  }

  @override
  Duration get transitionDuration => Constant.DropdowmMenuDuration;

}

class DropdwonRoutePage<T> extends StatelessWidget {
  const DropdwonRoutePage({
    Key? key,
    required this.buttonRect,
    required this.itemHeight,
    this.items,
    this.customItemsHeights,
    this.style,
    this.searchMatch,
    this.searchInnerWidget,
    this.searchController,
    this.scrollbarThickness,
    this.scrollbarRadius,
    this.scrollbarAlwaysShow,
    required this.offset,
    this.menuMaxHeight,
    this.itemWidth,
    this.dropdownScrollPadding,
    this.dropdownPadding,
    this.dropdownDecoration,
    required this.capturedThemes,
    required this.elevation,
    required this.selectedIndex,
    required this.enableFeedback,
    required this.padding,
    required this.route,
    required this.constraints,
  }) : super(key: key);

  final DropdwonRoute<T> route;
  final BoxConstraints constraints;
  final List<MenuItem<T>>? items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final int selectedIndex;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final bool enableFeedback;
  final BoxDecoration? dropdownDecoration;
  final EdgeInsetsGeometry? dropdownPadding;
  final EdgeInsetsGeometry? dropdownScrollPadding;
  final double? menuMaxHeight;
  final double itemHeight;
  final double? itemWidth;
  final Radius? scrollbarRadius;
  final double? scrollbarThickness;
  final bool? scrollbarAlwaysShow;
  final Offset offset;
  final List<double>? customItemsHeights;
  final TextEditingController? searchController;
  final Widget? searchInnerWidget;
  final SearchMatch? searchMatch;

  @override
  Widget build(BuildContext context) {

    assert(debugCheckHasDirectionality(context));

    if (route.scrollController == null) {
      final MenuLimits menuLimits =
      route.getMenuLimits(buttonRect, constraints.maxHeight, selectedIndex);
      route.scrollController =
          ScrollController(initialScrollOffset: menuLimits.scrollOffset);
    }

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = DropdwonMenu<T>(
      route: route,
      padding: padding.resolve(textDirection),
      buttonRect: buttonRect,
      constraints: constraints,
      enableFeedback: enableFeedback,
      itemHeight: itemHeight,
      dropdownDecoration: dropdownDecoration,
      dropdownPadding: dropdownPadding,
      dropdownScrollPadding: dropdownScrollPadding,
      scrollbarRadius: scrollbarRadius,
      scrollbarThickness: scrollbarThickness,
      scrollbarAlwaysShow: scrollbarAlwaysShow,
      offset: offset,
      customItemsHeights: customItemsHeights,
      searchController: searchController,
      searchInnerWidget: searchInnerWidget,
      searchMatch: searchMatch,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: DropdwonMenuRouteLayout<T>(
              buttonRect: buttonRect,
              route: route,
              textDirection: textDirection,
              itemHeight: itemHeight,
              itemWidth: itemWidth,
              offset: offset,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

class MenuItem<T> extends SingleChildRenderObjectWidget {

  MenuItem({
    super.key,
    this.item,
    required this.onLayout,
  }) : super(child: item);

  final ValueChanged<Size> onLayout;
  final DropdownMenuItem<T>? item;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class RenderMenuItem extends RenderProxyBox {

  ValueChanged<Size> onLayout;

  RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  @override
  void performLayout() {
    super.performLayout();
    onLayout(size);
  }
}

class DropdwonMenuItemContainert extends StatelessWidget {
  const DropdwonMenuItemContainert({
    Key? key,
    this.alignment = AlignmentDirectional.centerStart,
    required this.child
  }) : super(key: key);

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: Constant.MenuItemHeight),
      alignment: alignment,
      child: child,
    );
  }
}

class CustomDropdwon<T> extends StatefulWidget {
   CustomDropdwon({
    Key? key,
    this.alignment = AlignmentDirectional.centerStart,
    this.offset,
    this.itemHeight = kMinInteractiveDimension,
    this.customItemsHeights,
    this.searchMatch,
    this.searchInnerWidget,
    this.searchController,
    this.scrollbarThickness,
    this.scrollbarRadius,
    this.scrollbarAlwaysShow,
    this.dropdownScrollPadding,
    this.dropdownPadding,
    this.dropdownDecoration,
    this.value,
    this.style,
    required this.items,
    this.barrierLabel,
    this.barrierColor,
    this.selectedItemHighlightColor,
    this.autofocus = false,
    this.buttonDecoration,
    this.buttonElevation,
    this.buttonHeight,
    this.buttonPadding,
    this.buttonWidth,
    this.customButton,
    this.disabledHint,
    this.dropdownElevation = 8,
    this.dropdownFullScreen = false,
    this.dropdownMaxHeight,
    this.dropdownOverButton = false,
    this.dropdownWidth,
    this.focusColor,
    this.focusNode,
    this.formFieldCallBack,
    this.hint,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconOnClick,
    this.iconSize = 24,
    this.isDense = false,
    this.isExpanded = false,
    this.itemPadding,
    this.onChanged,
    this.onMenuStateChange,
    this.openWithLongPress = false,
    this.selectedItemBuilder,
    this.underline,
     this.barrierDismissible = true,
     this.enableFeedback
  }) : assert(
   items == null ||
       items.isEmpty ||
       value == null ||
       items.where((DropdownMenuItem<T> item) {
         return item.value == value;
       }).length ==
           1,
   "There should be exactly one item with [DropdownButtonFormField]'s value: "
       '$value. \n'
       'Either zero or 2 or more [DropdownMenuItem]s were detected '
       'with the same value',
   );

  CustomDropdwon._formField({
    super.key,
    required this.items,
    this.selectedItemBuilder,
    this.value,
    this.hint,
    this.disabledHint,
    required this.onChanged,
    this.onMenuStateChange,
    this.dropdownElevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconOnClick,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight = kMinInteractiveDimension,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.buttonHeight,
    this.buttonWidth,
    this.buttonPadding,
    this.buttonDecoration,
    this.buttonElevation,
    this.itemPadding,
    this.dropdownWidth,
    this.dropdownPadding,
    this.dropdownScrollPadding,
    this.dropdownDecoration,
    this.selectedItemHighlightColor,
    this.scrollbarRadius,
    this.scrollbarThickness,
    this.scrollbarAlwaysShow,
    this.offset,
    this.customButton,
    this.customItemsHeights,
    this.openWithLongPress = false,
    this.dropdownOverButton = false,
    this.dropdownFullScreen = false,
    this.barrierDismissible = true,
    this.barrierColor,
    this.barrierLabel,
    this.searchController,
    this.searchInnerWidget,
    this.searchMatch,
    this.formFieldCallBack,
  }) : assert(
  items == null ||
      items.isEmpty ||
      value == null ||
      items.where((DropdownMenuItem<T> item) {
        return item.value == value;
      }).length ==
          1,
  "There should be exactly one item with [DropdownButtonFormField]'s value: "
      '$value. \n'
      'Either zero or 2 or more [DropdownMenuItem]s were detected '
      'with the same value',
  );

  final double? buttonHeight;
  final double? buttonWidth;
  final EdgeInsetsGeometry? buttonPadding;
  final BoxDecoration? buttonDecoration;
  final int? buttonElevation;
  final EdgeInsetsGeometry? itemPadding;
  final double? dropdownWidth;
  final EdgeInsetsGeometry? dropdownPadding;
  final EdgeInsetsGeometry? dropdownScrollPadding;
  final BoxDecoration? dropdownDecoration;
  final Color? selectedItemHighlightColor;
  final Radius? scrollbarRadius;
  final double? scrollbarThickness;
  final bool? scrollbarAlwaysShow;
  final Offset? offset;
  final Widget? customButton;
  final List<double>? customItemsHeights;
  final bool openWithLongPress;
  final bool dropdownOverButton;
  final bool dropdownFullScreen;
  final Widget? iconOnClick;
  final OnMenuStateChange? onMenuStateChange;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;
  final TextEditingController? searchController;
  final Widget? searchInnerWidget;
  final SearchMatch? searchMatch;
  final List<DropdownMenuItem<T>>? items;
  final T? value;
  final Widget? hint;
  final Widget? disabledHint;
  final ValueChanged<T?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final int dropdownElevation;
  final TextStyle? style;
  final Widget? underline;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final bool isDense;
  final bool isExpanded;
  final double itemHeight;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final double? dropdownMaxHeight;
  final AlignmentGeometry alignment;
  final OnMenuStateChange? formFieldCallBack;
  final bool? enableFeedback;

  @override
  State<CustomDropdwon<T>> createState() => _CustomDropdwonState<T>();
}

class _CustomDropdwonState<T> extends State<CustomDropdwon<T>> with WidgetsBindingObserver{

  int? _selectedIndex;
  DropdwonRoute<T>? _dropdownRoute;
  Orientation? _lastOrientation;
  FocusNode? _internalNode;

  FocusNode? get focusNode => widget.focusNode ?? _internalNode;
  bool _hasPrimaryFocus = false;
  late Map<Type, Action<Intent>> _actionMap;
  bool _isMenuOpen = false;

  final _rect = ValueNotifier<Rect?>(null);

  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    updateSelectedIndex();
    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) => _handleTap(),
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) => _handleTap(),
      ),
    };
    focusNode!.addListener(handleFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    focusNode!.removeListener(handleFocusChanged);
    _internalNode?.dispose();
    super.dispose();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
    _lastOrientation = null;
  }

  void handleFocusChanged() {
    if (_hasPrimaryFocus != focusNode!.hasPrimaryFocus) {
      setState(() {
        _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
      });
    }
  }

  @override
  void didUpdateWidget(CustomDropdwon<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(handleFocusChanged);
      if (widget.focusNode == null) {
        _internalNode ??= _createFocusNode();
      }
      _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
      focusNode!.addListener(handleFocusChanged);
    }
    updateSelectedIndex();
  }

  void updateSelectedIndex() {
    if (widget.items == null ||
        widget.items!.isEmpty ||
        (widget.value == null &&
            widget.items!
                .where((DropdownMenuItem<T> item) =>
            item.enabled && item.value == widget.value)
                .isEmpty)) {
      _selectedIndex = null;
      return;
    }

    assert(widget.items!
        .where((DropdownMenuItem<T> item) => item.value == widget.value)
        .length ==
        1);
    for (int itemIndex = 0; itemIndex < widget.items!.length; itemIndex++) {
      if (widget.items![itemIndex].value == widget.value) {
        _selectedIndex = itemIndex;
        return;
      }
    }
  }

  @override
  void didChangeMetrics() {
    if (_rect.value == null) return;
    final _newRect = _getRect();
    if (_rect.value!.top == _newRect.top) return;
    _rect.value = _newRect;
  }

  TextStyle? get _textStyle =>
      widget.style ?? Theme.of(context).textTheme.subtitle1;

  Rect _getRect() {
    final TextDirection? textDirection = Directionality.maybeOf(context);
    const EdgeInsetsGeometry menuMargin = EdgeInsets.zero;
    final NavigatorState navigator =
    Navigator.of(context, rootNavigator: widget.dropdownFullScreen);

    final RenderBox itemBox = context.findRenderObject()! as RenderBox;
    final Rect itemRect = itemBox.localToGlobal(Offset.zero,
        ancestor: navigator.context.findRenderObject()) &
    itemBox.size;

    return menuMargin.resolve(textDirection).inflateRect(itemRect);
  }

  void _handleTap() {
    final TextDirection? textDirection = Directionality.maybeOf(context);

    final List<MenuItem<T>> menuItems = <MenuItem<T>>[
      for (int index = 0; index < widget.items!.length; index += 1)
        MenuItem<T>(
          item: widget.items![index],
          onLayout: (Size size) {
            if (_dropdownRoute == null) return;

            _dropdownRoute!.itemHeights[index] = size.height;
          },
        ),
    ];

    final NavigatorState navigator =
    Navigator.of(context, rootNavigator: widget.dropdownFullScreen);
    assert(_dropdownRoute == null);
    _rect.value = _getRect();
    _dropdownRoute = DropdwonRoute<T>(
      items: menuItems,
      buttonRect: _rect,
      padding: widget.itemPadding ?? Constant.MenuItemPadding.resolve(textDirection),
      selectedIndex: _selectedIndex ?? 0,
      isNoSelectedItem: _selectedIndex == null,
      selectedItemHighlightColor: widget.selectedItemHighlightColor,
      elevation: widget.dropdownElevation,
      capturedThemes:
      InheritedTheme.capture(from: context, to: navigator.context),
      style: _textStyle!,
      barrierDismissible: widget.barrierDismissible,
      barrierColor: widget.barrierColor,
      barrierLabel: widget.barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      enableFeedback: widget.enableFeedback ?? true,
      itemHeight: widget.itemHeight,
      itemWidth: widget.dropdownWidth,
      menuMaxHeight: widget.dropdownMaxHeight,
      dropdownDecoration: widget.dropdownDecoration,
      dropdownPadding: widget.dropdownPadding,
      dropdownScrollPadding: widget.dropdownScrollPadding,
      scrollbarRadius: widget.scrollbarRadius,
      scrollbarThickness: widget.scrollbarThickness,
      scrollbarAlwaysShow: widget.scrollbarAlwaysShow,
      offset: widget.offset ?? const Offset(0, 0),
      showAboveButton: widget.dropdownOverButton,
      customItemsHeights: widget.customItemsHeights,
      searchController: widget.searchController,
      searchInnerWidget: widget.searchInnerWidget,
      searchMatch: widget.searchMatch,
    );

    _isMenuOpen = true;
    focusNode?.requestFocus();
    navigator
        .push(_dropdownRoute!)
        .then<void>((DropdwonRouteResult<T>? newValue) {
      _removeDropdownRoute();
      _isMenuOpen = false;
      widget.onMenuStateChange?.call(false);
      widget.formFieldCallBack?.call(false);
      if (!mounted || newValue == null) return;
      widget.onChanged?.call(newValue.result);
    });

    widget.onMenuStateChange?.call(true);
    widget.formFieldCallBack?.call(true);
  }

  void callTap() => _handleTap();

  double get _denseButtonHeight {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double fontSize = _textStyle!.fontSize ??
        Theme.of(context).textTheme.subtitle1!.fontSize!;
    final double scaledFontSize = textScaleFactor * fontSize;
    return max(
        scaledFontSize, max(widget.iconSize, Constant.ButtonHeight));
  }

  Color get iconColor {
    if (_enabled) {
      if (widget.iconEnabledColor != null) return widget.iconEnabledColor!;

      switch (Theme.of(context).brightness) {
        case Brightness.light:
          return Colors.grey.shade700;
        case Brightness.dark:
          return Colors.white70;
      }
    } else {
      if (widget.iconDisabledColor != null) return widget.iconDisabledColor!;

      switch (Theme.of(context).brightness) {
        case Brightness.light:
          return Colors.grey.shade400;
        case Brightness.dark:
          return Colors.white10;
      }
    }
  }

  bool get _enabled =>
      widget.items != null &&
          widget.items!.isNotEmpty &&
          widget.onChanged != null;

  Orientation getOrientation(BuildContext context) {
    Orientation? result = MediaQuery.maybeOf(context)?.orientation;
    if (result == null) {
      final Size size = WidgetsBinding.instance.window.physicalSize;
      result = size.width > size.height
          ? Orientation.landscape
          : Orientation.portrait;
    }
    return result;
  }


  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final Orientation newOrientation = getOrientation(context);
    _lastOrientation ??= newOrientation;
    if (newOrientation != _lastOrientation) {
      _removeDropdownRoute();
      _lastOrientation = newOrientation;
    }

    final List<Widget> items = widget.selectedItemBuilder == null
        ? (widget.items != null ? List<Widget>.of(widget.items!) : <Widget>[])
        : List<Widget>.of(widget.selectedItemBuilder!(context));

    int? hintIndex;
    if (widget.hint != null || (!_enabled && widget.disabledHint != null)) {
      final Widget displayedHint =
      _enabled ? widget.hint! : widget.disabledHint ?? widget.hint!;

      hintIndex = items.length;
      items.add(DefaultTextStyle(
        style: _textStyle!.copyWith(color: Theme.of(context).hintColor),
        child: IgnorePointer(
          ignoringSemantics: false,
          child: DropdwonMenuItemContainert(
            alignment: widget.alignment,
            child: displayedHint,
          ),
        ),
      ));
    }

    final EdgeInsetsGeometry padding = ButtonTheme.of(context).alignedDropdown
        ? Constant.AlignedButtonPadding
        : Constant.UnalignedButtonPadding;

    final Widget innerItemsWidget;
    if (items.isEmpty) {
      innerItemsWidget = const SizedBox.shrink();
    } else {
      innerItemsWidget = IndexedStack(
        index: _selectedIndex ?? hintIndex,
        alignment: widget.alignment,
        children: widget.isDense
            ? items
            : items.map((Widget item) {
          return SizedBox(height: widget.itemHeight, child: item);
        }).toList(),
      );
    }

    Widget result = DefaultTextStyle(
      style: _enabled
          ? _textStyle!
          : _textStyle!.copyWith(color: Theme.of(context).disabledColor),
      child: widget.customButton ??
          Container(
            decoration: widget.buttonDecoration?.copyWith(
              boxShadow: widget.buttonDecoration!.boxShadow ??
                  kElevationToShadow[widget.buttonElevation ?? 0],
            ),
            padding: widget.buttonPadding ??
                padding.resolve(Directionality.of(context)),
            height: widget.buttonHeight ??
                (widget.isDense ? _denseButtonHeight : null),
            width: widget.buttonWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.isExpanded)
                  Expanded(child: innerItemsWidget)
                else
                  innerItemsWidget,
                /*IconTheme(
                  data: IconThemeData(
                    color: iconColor,
                    size: widget.iconSize,
                  ),
                  child: widget.iconOnClick != null
                      ? _isMenuOpen
                      ? widget.iconOnClick!
                      : widget.icon!
                      : widget.icon ?? defaultIcon,
                ),*/
              ],
            ),
          ),
    );

    if (!DropdownButtonHideUnderline.at(context)) {
      final double bottom = widget.isDense ? 0.0 : 8.0;
      result = Stack(
        children: <Widget>[
          result,
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: bottom,
            child: widget.underline ??
                Container(
                  height: 1.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 0.0,
                      ),
                    ),
                  ),
                ),
          ),
        ],
      );
    }

    final MouseCursor effectiveMouseCursor =
    MaterialStateProperty.resolveAs<MouseCursor>(
      MaterialStateMouseCursor.clickable,
      <MaterialState>{
        if (!_enabled) MaterialState.disabled,
      },
    );

    return Semantics(
      button: true,
      child: Actions(
        actions: _actionMap,
        child: InkWell(
          mouseCursor: effectiveMouseCursor,
          onTap: _enabled && !widget.openWithLongPress ? _handleTap : null,
          onLongPress: _enabled && widget.openWithLongPress ? _handleTap : null,
          canRequestFocus: _enabled,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          focusColor: widget.buttonDecoration?.color ??
              widget.focusColor ??
              Theme.of(context).focusColor,
          enableFeedback: false,
          child: result,
          borderRadius: widget.buttonDecoration?.borderRadius
              ?.resolve(Directionality.of(context)),
        ),
      ),
    );
  }
}

class DropdwonFormField<T> extends FormField<T> {
  DropdwonFormField({ super.key,
    required List<DropdownMenuItem<T>>? items,
    DropdownButtonBuilder? selectedItemBuilder,
    T? value,
    Widget? hint,
    Widget? disabledHint,
    this.onChanged,
    int dropdownElevation = 8,
    TextStyle? style,
    Widget? icon,
    Widget? iconOnClick,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    double iconSize = 24.0,
    bool isDense = true,
    bool isExpanded = false,
    double itemHeight = kMinInteractiveDimension,
    Color? focusColor,
    FocusNode? focusNode,
    bool autofocus = false,
    InputDecoration? decoration,
    super.onSaved,
    super.validator,
    AutovalidateMode? autovalidateMode,
    double? dropdownMaxHeight,
    bool? enableFeedback,
    AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    double? buttonHeight,
    double? buttonWidth,
    EdgeInsetsGeometry? buttonPadding,
    BoxDecoration? buttonDecoration,
    int? buttonElevation,
    EdgeInsetsGeometry? itemPadding,
    double? dropdownWidth,
    EdgeInsetsGeometry? dropdownPadding,
    EdgeInsetsGeometry? dropdownScrollPadding,
    BoxDecoration? dropdownDecoration,
    Color? selectedItemHighlightColor,
    Radius? scrollbarRadius,
    double? scrollbarThickness,
    bool? scrollbarAlwaysShow,
    Offset? offset,
    Widget? customButton,
    List<double>? customItemsHeights,
    bool openWithLongPress = false,
    bool dropdownOverButton = false,
    bool dropdownFullScreen = false,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    TextEditingController? searchController,
    Widget? searchInnerWidget,
    SearchMatch? searchMatchFn,
    OnMenuStateChange? onMenuStateChange,}) : assert(
  items == null ||
      items.isEmpty ||
      value == null ||
      items.where((DropdownMenuItem<T> item) {
        return item.value == value;
      }).length ==
          1,
  "There should be exactly one item with [DropdownButton]'s value: "
      '$value. \n'
      'Either zero or 2 or more [DropdownMenuItem]s were detected '
      'with the same value',
  ),
        decoration = decoration ?? InputDecoration(focusColor: focusColor),
        super(
        initialValue: value,
        autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
        builder: (FormFieldState<T> field) {
          final DropdwonFormFieldState<T> state =
          field as DropdwonFormFieldState<T>;
          final InputDecoration decorationArg =
              decoration ?? InputDecoration(focusColor: focusColor);
          final InputDecoration effectiveDecoration =
          decorationArg.applyDefaults(
            Theme.of(field.context).inputDecorationTheme,
          );

          final bool showSelectedItem = items != null &&
              items
                  .where(
                      (DropdownMenuItem<T> item) => item.value == state.value)
                  .isNotEmpty;
          bool isHintOrDisabledHintAvailable() {
            final bool isDropdownDisabled =
                onChanged == null || (items == null || items.isEmpty);
            if (isDropdownDisabled) {
              return hint != null || disabledHint != null;
            } else {
              return hint != null;
            }
          }

          final bool isEmpty =
              !showSelectedItem && !isHintOrDisabledHintAvailable();

          bool hasFocus = false;

          return Focus(
            canRequestFocus: false,
            skipTraversal: true,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return InputDecorator(
                  decoration: effectiveDecoration.copyWith(
                      errorText: field.errorText),
                  isEmpty: isEmpty,
                  isFocused: hasFocus,
                  textAlignVertical: TextAlignVertical.bottom,
                  child: DropdownButtonHideUnderline(
                    child: CustomDropdwon._formField(
                      items: items,
                      selectedItemBuilder: selectedItemBuilder,
                      value: state.value,
                      hint: hint,
                      disabledHint: disabledHint,
                      onChanged: onChanged == null ? null : state.didChange,
                      dropdownElevation: dropdownElevation,
                      style: style,
                      icon: icon,
                      iconOnClick: iconOnClick,
                      iconDisabledColor: iconDisabledColor,
                      iconEnabledColor: iconEnabledColor,
                      iconSize: iconSize,
                      isDense: isDense,
                      isExpanded: isExpanded,
                      itemHeight: itemHeight,
                      focusColor: focusColor,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      dropdownMaxHeight: dropdownMaxHeight,
                      enableFeedback: enableFeedback,
                      alignment: alignment,
                      buttonHeight: buttonHeight,
                      buttonWidth: buttonWidth,
                      buttonPadding: buttonPadding,
                      buttonDecoration: buttonDecoration,
                      buttonElevation: buttonElevation,
                      itemPadding: itemPadding,
                      dropdownWidth: dropdownWidth,
                      dropdownPadding: dropdownPadding,
                      dropdownScrollPadding: dropdownScrollPadding,
                      dropdownDecoration: dropdownDecoration,
                      selectedItemHighlightColor: selectedItemHighlightColor,
                      scrollbarRadius: scrollbarRadius,
                      scrollbarThickness: scrollbarThickness,
                      scrollbarAlwaysShow: scrollbarAlwaysShow,
                      offset: offset,
                      customButton: customButton,
                      customItemsHeights: customItemsHeights,
                      openWithLongPress: openWithLongPress,
                      dropdownOverButton: dropdownOverButton,
                      dropdownFullScreen: dropdownFullScreen,
                      onMenuStateChange: onMenuStateChange,
                      barrierDismissible: barrierDismissible,
                      barrierColor: barrierColor,
                      barrierLabel: barrierLabel,
                      searchController: searchController,
                      searchInnerWidget: searchInnerWidget,
                      searchMatch: searchMatchFn,
                      formFieldCallBack: (isOpen) {
                        hasFocus = isOpen;
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      );

  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;

  @override
  FormFieldState<T> createState() => DropdwonFormFieldState<T>();
}

class DropdwonFormFieldState<T> extends FormFieldState<T> {
  @override
  void didChange(T? value) {
    super.didChange(value);
    final DropdwonFormField<T> dropdownButtonFormField =
    widget as DropdwonFormField<T>;
    assert(dropdownButtonFormField.onChanged != null);
    dropdownButtonFormField.onChanged!(value);
  }

  @override
  void didUpdateWidget(DropdwonFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}





