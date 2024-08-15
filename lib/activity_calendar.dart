import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef IndexedOnTap = void Function(int index);

typedef TextTooltipBuilder = String Function(int index);

typedef RichTooltipBuilder = InlineSpan Function(int index);

/// Class that represent builder of tooltip for each item of [ActivityCalendar].
///
/// To create just one string tooltips use `TooltipBuilder.text` constructor.
/// If you need to customize part of your tooltip's message, then
/// you should use `TooltipBuilder.rich` constructor.
///
/// Both constructors have almost all arguments that [Tooltip] can have,
/// so you can customize it's behavior.
class TooltipBuilder {
  /// Rich text builder
  const TooltipBuilder.rich({
    required this.builder,
    this.decoration,
    this.preferBelow,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.excludeFromSemantics,
    this.waitDuration,
    this.enableFeedback,
  });

  /// Simple text builder.
  /// Have optional `TextStyle? textStyle` argument.
  TooltipBuilder.text({
    required TextTooltipBuilder builder,
    this.decoration,
    this.preferBelow,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.excludeFromSemantics,
    TextStyle? textStyle,
    this.waitDuration,
    this.enableFeedback,
  }) : builder = ((int i) => TextSpan(text: builder(i), style: textStyle));

  /// Builder that will be use for generate messages for tooltips
  final RichTooltipBuilder builder;

  /// The amount of space by which to inset the tooltip's [child].
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry? padding;

  /// The empty space that surrounds the tooltip.
  ///
  /// Defines the tooltip's outer [Container.margin]. By default, a
  /// long tooltip will span the width of its window. If long enough,
  /// a tooltip might also span the window's height. This property allows
  /// one to define how much space the tooltip must be inset from the edges
  /// of their display window.
  ///
  /// If this property is null, then [TooltipThemeData.margin] is used.
  /// If [TooltipThemeData.margin] is also null, the default margin is
  /// 0.0 logical pixels on all sides.
  final EdgeInsetsGeometry? margin;

  /// The vertical gap between the widget and the displayed tooltip.
  ///
  /// When [preferBelow] is set to true and tooltips have sufficient space to
  /// display themselves, this property defines how much vertical space
  /// tooltips will position themselves under their corresponding widgets.
  /// Otherwise, tooltips will position themselves above their corresponding
  /// widgets with the given offset.
  final double? verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool? preferBelow;

  /// Whether the tooltip's [message] or [richMessage] should be excluded from
  /// the semantics tree.
  ///
  /// Defaults to false. A tooltip will add a [Semantics] label that is set to
  /// [Tooltip.message] if non-null, or the plain text value of
  /// [Tooltip.richMessage] otherwise. Set this property to true if the app is
  /// going to provide its own custom semantics label.
  final bool? excludeFromSemantics;

  /// Specifies the tooltip's shape and background color.
  ///
  /// The tooltip shape defaults to a rounded rectangle with a border radius of
  /// 4.0. Tooltips will also default to an opacity of 90% and with the color
  /// [Colors.grey]\[700\] if [ThemeData.brightness] is [Brightness.dark], and
  /// [Colors.white] if it is [Brightness.light].
  final Decoration? decoration;

  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  ///
  /// Defaults to 0 milliseconds (tooltips are shown immediately upon hover).
  final Duration? waitDuration;

  /// The length of time that the tooltip will be shown after a long press
  /// is released or mouse pointer exits the widget.
  ///
  /// Defaults to 1.5 seconds for long press released or 0.1 seconds for mouse
  /// pointer exits the widget.
  final Duration? showDuration = const Duration(milliseconds: 3000);

  /// The [TooltipTriggerMode] that will show the tooltip.
  ///
  /// If this property is null, then [TooltipThemeData.triggerMode] is used.
  /// If [TooltipThemeData.triggerMode] is also null, the default mode is
  /// [TooltipTriggerMode.tap].
  final TooltipTriggerMode? triggerMode = TooltipTriggerMode.tap;

  /// Whether the tooltip should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// When null, the default value is true.
  ///
  /// See also:
  ///
  ///  * [Feedback], for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;
}

class ActivityCalendar extends StatelessWidget {
  const ActivityCalendar({
    Key? key,
    this.fromColor,
    this.toColor,
    this.steps = 5,
    required this.activities,
    this.weekday,
    this.spacing = 3,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.clipBehavior = Clip.hardEdge,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.semanticChildCount,
    this.cacheExtent,
    this.primary,
    this.controller,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.tooltipBuilder,
  })  : assert(steps >= 2),
        super(key: key);

  /// Color that represents item with no activity.
  /// If [null], then use Theme's [ColorScheme.surface].
  final Color? fromColor;

  /// Color that represents item with max activity.
  /// If [null], then use Theme's [ColorScheme.primary].
  final Color? toColor;

  /// Count of color steps including [fromColor] and [toColor].
  /// By default is 5.
  final int steps;

  /// List of activity per days.
  /// Each index represent another day from first one to last one.
  final List<int> activities;

  /// Weekday that calendar starts from.
  /// If [null], then check today weekday.
  ///
  /// Use [DateTime] weekdays constants for that.
  final int? weekday;

  /// Spacing between elements, both horizontal and vertical.
  /// By default is 3.
  final double spacing;

  /// Optional on tap callback.
  /// Gives index of item by [activities].
  final IndexedOnTap? onTap;

  /// Border radius of each item.
  /// By default radius is 8.
  final BorderRadius borderRadius;

  /// Optional tooltip builder for each item.
  /// See [TooltipBuilder] for more info.
  ///
  /// If [null] then items will have no tooltips.
  ///
  /// Work by default [Tooltip] class, so it's already adaptive.
  final TooltipBuilder? tooltipBuilder;

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  /// {@macro flutter.widgets.scroll_view.reverse}
  final bool reverse;

  final EdgeInsetsGeometry? padding;

  /// {@macro flutter.widgets.scroll_view.physics}
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scroll_view.shrinkWrap}
  final bool shrinkWrap;

  /// {@macro flutter.material.Material.clipBehavior}
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.widgets.scrollable.semanticChildCount}
  final int? semanticChildCount;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// {@macro flutter.widgets.scroll_view.controller}
  final ScrollController? controller;

  final bool addAutomaticKeepAlives;

  final bool addRepaintBoundaries;

  final bool addSemanticIndexes;

  /// Helper method that calculate the actual index of item.
  static int _calculateIndex(int i, int weekday) {
    return 6 - i + (7 * ((i ~/ 7) * 2)) - (7 - weekday);
  }

  /// Helper method that calculate the actual child count for given data.
  static int _calculateChildCount(List<int> activities, int weekday) {
    return activities.length + // actually days
        (7 - weekday) + // skip in first line
        (7 - (activities.length + 7 - weekday) % 7) % 7; // skip on last line
  }

  /// Helper method that give us map of each step to it's widget.
  static Map<int, Widget> tiles(
    Color from,
    Color to,
    int steps,
    int max,
    BorderRadius borderRadius,
  ) {
    final map = <int, Widget>{};
    final da = to.alpha - from.alpha;
    final dr = to.red - from.red;
    final dg = to.green - from.green;
    final db = to.blue - from.blue;
    for (int i = 0; i < steps; i++) {
      if (i == 0) {
        const color = Colors.grey;
        map[i] = Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
        );
        continue;
      }
      final index = (i + 0 * (max / (steps - 1))).toInt();
      final color = Color.fromARGB(
        (from.alpha + i * (da / (steps - 1))).toInt(),
        (from.red + i * (dr / (steps - 1))).toInt(),
        (from.green + i * (dg / (steps - 1))).toInt(),
        (from.blue + i * (db / (steps - 1))).toInt(),
      );
      map[index] = Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      );
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final weekday = this.weekday ?? DateTime.now().weekday;

    final mapOfTiles = tiles(
      fromColor ?? Theme.of(context).colorScheme.surface,
      toColor ?? Theme.of(context).colorScheme.primary,
      steps,
      activities.fold(0, (prev, curr) => curr > prev ? curr : prev),
      borderRadius,
    );

    int _findSegment(int activity) {
      return mapOfTiles.keys.firstWhere(
        (key) => activity <= key,
        orElse: () => mapOfTiles.keys.last,
      );
    }

    // Calculate segments (steps) once, so we don't do it every time.
    final segments = List.generate(
      activities.length,
      (i) => _findSegment(activities[i]),
      growable: false,
    );

    return GridView.builder(
      padding: padding,
      scrollDirection: scrollDirection,
      reverse: reverse,
      physics: physics,
      shrinkWrap: shrinkWrap,
      clipBehavior: clipBehavior,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      semanticChildCount: semanticChildCount,
      cacheExtent: cacheExtent,
      primary: primary,
      controller: controller,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: _calculateChildCount(segments, weekday),
      itemBuilder: (context, i) {
        final index = _calculateIndex(i, weekday);
        if (index < 0 || index >= activities.length) {
          return const SizedBox();
        }

        final segment = segments[index];
        Widget item = mapOfTiles[segment]!;

        if (onTap != null) {
          item = GestureDetector(
            onTap: () => onTap!(index),
            child: item,
          );
        }

        if (tooltipBuilder != null) {
          item = Tooltip(
            richMessage: tooltipBuilder!.builder(index),
            decoration: tooltipBuilder!.decoration,
            preferBelow: tooltipBuilder!.preferBelow,
            margin: tooltipBuilder!.margin,
            showDuration: tooltipBuilder!.showDuration,
            padding: tooltipBuilder!.padding,
            enableFeedback: tooltipBuilder!.enableFeedback,
            excludeFromSemantics: tooltipBuilder!.excludeFromSemantics,
            triggerMode: tooltipBuilder!.triggerMode,
            verticalOffset: tooltipBuilder!.verticalOffset,
            waitDuration: tooltipBuilder!.waitDuration,
            child: item,
          );
        }

        return item;
      },
    );
  }
}
