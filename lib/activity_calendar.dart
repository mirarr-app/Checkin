import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef IndexedOnTap = void Function(int index);



typedef TextTooltipBuilder = String Function(int index);

typedef RichTooltipBuilder = InlineSpan Function(int index);

class TooltipBuilder {
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

  final RichTooltipBuilder builder;

  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  final double? verticalOffset;

  final bool? preferBelow;

  final bool? excludeFromSemantics;

  final Decoration? decoration;

  final Duration? waitDuration;

  final Duration? showDuration = const Duration(milliseconds: 3000);

  final TooltipTriggerMode? triggerMode = TooltipTriggerMode.tap;

  final bool? enableFeedback;
}

class ActivityCalendar extends StatelessWidget {
  const ActivityCalendar({
    super.key,
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
  })  : assert(steps >= 2);

  final Color? fromColor;

  final Color? toColor;

  final int steps;

  final List<int> activities;

  final int? weekday;

  final double spacing;

  final IndexedOnTap? onTap;

  final BorderRadius borderRadius;

  final TooltipBuilder? tooltipBuilder;

  final Axis scrollDirection;

  final bool reverse;

  final EdgeInsetsGeometry? padding;

  final ScrollPhysics? physics;

  final bool shrinkWrap;

  final Clip clipBehavior;

  final DragStartBehavior dragStartBehavior;

  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  final String? restorationId;

  final int? semanticChildCount;

  final double? cacheExtent;

  final bool? primary;

  final ScrollController? controller;

  final bool addAutomaticKeepAlives;

  final bool addRepaintBoundaries;

  final bool addSemanticIndexes;

  static int _calculateIndex(int i, int weekday) {
    return 6 - i + (7 * ((i ~/ 7) * 2)) - (7 - weekday);
  }

  static int _calculateChildCount(List<int> activities, int weekday) {
    return activities.length + // actually days
        (7 - weekday) + // skip in first line
        (7 - (activities.length + 7 - weekday) % 7) % 7; // skip on last line
  }

  static Map<int, Widget> tiles(
    Color from,
    Color to,
    int steps,
    int max,
    BorderRadius borderRadius,
  ) {
    final map = <int, Widget>{};
    final da = (to.a - from.a) * 255;
    final dr = (to.r - from.r) * 255;
    final dg = (to.g - from.g) * 255;
    final db = (to.b - from.b) * 255;
    final fromA = (from.a * 255).round();
    final fromR = (from.r * 255).round();
    final fromG = (from.g * 255).round();
    final fromB = (from.b * 255).round();
    for (int i = 0; i < steps; i++) {
      if (i == 0) {
        final color = Colors.grey.withValues(alpha: 0.2);
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
        (fromA + i * (da / (steps - 1))).round().clamp(0, 255),
        (fromR + i * (dr / (steps - 1))).round().clamp(0, 255),
        (fromG + i * (dg / (steps - 1))).round().clamp(0, 255),
        (fromB + i * (db / (steps - 1))).round().clamp(0, 255),
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

    int findSegment(int activity) {
      return mapOfTiles.keys.firstWhere(
        (key) => activity <= key,
        orElse: () => mapOfTiles.keys.last,
      );
    }

    // Calculate segments (steps) once, so we don't do it every time.
    final segments = List.generate(
      activities.length,
      (i) => findSegment(activities[i]),
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
            onTap: () {
              HapticFeedback.lightImpact();
              onTap!(index);
            },
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
