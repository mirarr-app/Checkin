import 'package:Checkin/activity_calendar.dart';
import 'package:Checkin/core/app_config.dart';
import 'package:Checkin/core/services/version_check_service.dart';
import 'package:Checkin/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:url_launcher/url_launcher.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

const int numberOfZeroes = 365;
final DateFormat _weekdayFormat = DateFormat.E();
final DateFormat _tooltipFormat = DateFormat.MMMEd();
final List<String> _weekdays =
    List.generate(7, (i) => _weekdayFormat.format(DateTime(2000, 0, 6 + i)));

class CalendarData {
  String name;
  Map<String, int> activities;
  Color color;
  int max;
  int daysToShow;

  CalendarData({
    required this.name,
    required this.activities,
    required this.color,
    required this.max,
    this.daysToShow = 365,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'activities': activities,
        'color': color.toARGB32(),
        'max': max,
        'daysToShow': daysToShow,
      };

  factory CalendarData.fromJson(Map<String, dynamic> json) => CalendarData(
        name: json['name'],
        activities: Map<String, int>.from(json['activities']),
        color: json['color'] != null ? Color(json['color'] as int) : Colors.orange,
        max: json['max'] != null ? json['max'] as int : 10,
        daysToShow: json['daysToShow'] ?? 365,
      );
}

class _MainScreenState extends State<MainScreen> {
  late Box<Map> _calendarsBox;
  List<CalendarData> _calendars = [];
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late DateTime _today;
  bool _isLoading = true;
  bool _versionCheckDone = false;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _initHive();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate({bool manual = false}) async {
    if ((_versionCheckDone && !manual) || !mounted) return;
    _versionCheckDone = true;
    final latest = await checkForUpdate(appVersion);
    if (!mounted) return;
    if (latest != null) {
      _showUpdateDialog(latest);
    } else if (manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkin is up to date!'),
        ),
      );
    }
  }

  Future<void> _showUpdateDialog(String latestVersion) async {
    final context = this.context;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.amber),
            SizedBox(width: 8),
            Text('Update available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version of Checkin is available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Current: $appVersion  →  Latest: $latestVersion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              final uri = Uri.parse(releasesPageUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open releases'),
          ),
        ],
      ),
    );
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _calendarsBox = await Hive.openBox<Map>('calendars');
    _loadCalendars();
    setState(() {
      _isLoading = false;
    });
    homeScreenWidgetSync();
  }

  Future<void> homeScreenWidgetSync() async {
    if (_calendars.isEmpty) return;

    final widget = MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _calendars[0].name,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "RobotoMono",
                        fontWeight: FontWeight.bold,
                        color: _calendars[0].color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final weekday in _weekdays)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: SizedBox(
                                  height: 16,
                                  child: Text(
                                    weekday[0],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          width: 340,
                          height: 120,
                          child: ActivityCalendar(
                            activities: _generateDateKeys(_calendars[0].daysToShow)
                                .map((key) => _calendars[0].activities[key] ?? 0)
                                .toList(),
                            fromColor: Colors.grey[850],
                            toColor: _calendars[0].color,
                            steps: 5,
                            spacing: 3,
                            borderRadius: BorderRadius.circular(2),
                            weekday: DateTime.now().weekday,
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await HomeWidget.renderFlutterWidget(
      widget,
      key: 'CalendarWidget',
      logicalSize: const Size(400, 200),
    );

    await HomeWidget.updateWidget(name: 'ObservableWidget');
  }

  void _loadCalendars() {
    try {
      _calendars = _calendarsBox.values
          .map((e) => CalendarData.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (_calendars.isEmpty) {
        _calendars = [
          CalendarData(
            name: 'Daily Check-in',
            activities: _createEmptyCalendar(),
            color: const Color(0xFFFF9800),
            max: 10,
            daysToShow: 365,
          )
        ];
        _saveCalendars();
      } else {
        for (var calendar in _calendars) {
          _ensureDataShift(calendar.activities);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading calendars: $e');
      }
      _calendars = [
        CalendarData(
          name: 'Daily Check-in',
          activities: _createEmptyCalendar(),
          color: const Color(0xFFFF9800),
          max: 10,
          daysToShow: 365,
        )
      ];
      _saveCalendars();
    }
  }

  List<String> _generateDateKeys(int days) {
    return List.generate(days, (index) {
      final date = _today.subtract(Duration(days: index));
      return _dateFormat.format(date);
    });
  }

  void _ensureDataShift(Map<String, int> activities) {
    final todayKey = _dateFormat.format(_today);
    if (!activities.containsKey(todayKey)) {
      final newActivities = <String, int>{};
      newActivities[todayKey] = 0;

      _generateDateKeys(_sharedDaysCount(context) - 1).forEach((dateKey) {
        newActivities[dateKey] = activities[dateKey] ?? 0;
      });

      activities.clear();
      activities.addAll(newActivities);
    }
  }

  Future<void> _addNewCalendar() async {
    HapticFeedback.lightImpact();
    String? name = await _showNameDialog();
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      int? max = await _showMaxDialog();
      if (!mounted) return;
      Color? color = await _selectColor(context: context);
      if (!mounted) return;
      if (color != null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _calendars.add(CalendarData(
            name: name,
            activities: _createEmptyCalendar(),
            color: color,
            max: max ?? 10,
            daysToShow: 365,
          ));
          _saveCalendars();
        });
        homeScreenWidgetSync();
      }
    }
  }

  Future<Color?> _selectColor({required BuildContext context}) async {
    final List<Color> colorOptions = [
      const Color(0xFFFF5252),
      const Color(0xFF448AFF),
      const Color(0xFF69F0AE),
      const Color(0xFFFFD740),
      const Color(0xFFE040FB),
      const Color(0xFFFF9100),
      const Color(0xFFFF4081),
      const Color(0xFF18FFFF),
    ];

    final List<Shapes> m3eShapes = [
      Shapes.slanted,
      Shapes.arch,
      Shapes.circle,
      Shapes.square,
      Shapes.semicircle,
      Shapes.slanted,
      Shapes.arch,
      Shapes.circle,
    ];

    return showDialog<Color?>(
      context: context,
      builder: (BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              const Text('Expressive Palette'),
            ],
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(colorOptions.length, (index) {
                final color = colorOptions[index];
                final shape = m3eShapes[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(color);
                  },
                  child: ClipPath(
                    clipper: M3EClipper(shape),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: color,
                      child: Center(
                        child: Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _createEmptyCalendar() {
    final dateKeys = _generateDateKeys(_sharedDaysCount(context));
    return {for (var k in dateKeys) k: 0};
  }

  void _saveCalendars() {
    _calendarsBox.clear();
    for (var calendar in _calendars) {
      _calendarsBox.add(calendar.toJson());
    }
  }

  Future<int?> _showMaxDialog() async {
    double currentVal = 10.0;
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: scheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: scheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Daily Goal Target',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${currentVal.round()} activities/day',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      const SizedBox(height: 16),
                      M3ESlider(
                        value: currentVal,
                        min: 1.0,
                        max: 50.0,
                        onChanged: (val) {
                          setDialogState(() {
                            currentVal = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [5, 10, 15, 20, 30].map((preset) {
                          final isSelected = currentVal.round() == preset;
                          return ChoiceChip(
                            label: Text('$preset'),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setDialogState(() {
                                currentVal = preset.toDouble();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          M3EButton(
                            size: M3EButtonSize.md,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop(currentVal.round());
                            },
                            child: const Text('Set Goal'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Future<String?> _showNameDialog() async {
    String name = '';
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_calendar, color: scheme.primary),
              const SizedBox(width: 10),
              const Text('New Tracker'),
            ],
          ),
          content: TextField(
            autofocus: true,
            autocorrect: false,
            onChanged: (value) => name = value,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'e.g. Exercise, Reading, Coding',
              labelText: 'Tracker Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            M3EButton(
              size: M3EButtonSize.md,
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(name);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _incrementToday(int calendarIndex) {
    HapticFeedback.mediumImpact();
    final todayKey = _dateFormat.format(_today);
    setState(() {
      _calendars[calendarIndex].activities[todayKey] =
          (_calendars[calendarIndex].activities[todayKey] ?? 0) + 1;
      _saveCalendars();
    });
    homeScreenWidgetSync();
  }

  Future<bool> _deleteCalendar(int index) async {
    HapticFeedback.mediumImpact();
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Delete ${_calendars[index].name}?',
            style: TextStyle(
              color: _calendars[index].color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This action will permanently remove this activity calendar.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return confirmDelete ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 600;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCalendar,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 32,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(
                    'Checkin',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: M3ELoadingIndicator())
                  : _calendars.isEmpty
                      ? _buildEmptyState(context)
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12 : 24,
                            vertical: 8,
                          ),
                          child: M3EDismissibleCardList(
                            itemCount: _calendars.length,
                            style: const M3EDismissibleCardStyle(
                              outerRadius: 24.0,
                              innerRadius: 10.0,
                              gap: 12.0,
                            ),
                            onDismiss: (index, direction) async {
                              final confirmed = await _deleteCalendar(index);
                              if (confirmed) {
                                final deletedName = _calendars[index].name;
                                setState(() {
                                  _calendars.removeAt(index);
                                  _saveCalendars();
                                });
                                homeScreenWidgetSync();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "$deletedName"'),
                                    ),
                                  );
                                }
                                return true;
                              }
                              return false;
                            },
                            itemBuilder: (context, index) {
                              final calendar = _calendars[index];
                              final activityList = _generateDateKeys(calendar.daysToShow)
                                  .map((key) => calendar.activities[key] ?? 0)
                                  .toList();
                              final textColor = calendar.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: calendar.color.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            calendar.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: calendar.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton.filled(
                                              onPressed: () => _incrementToday(index),
                                              icon: Icon(
                                                Icons.add_rounded,
                                                size: 20,
                                                color: textColor,
                                              ),
                                              tooltip: 'Check in today',
                                              style: IconButton.styleFrom(
                                                backgroundColor: calendar.color,
                                                foregroundColor: textColor,
                                                elevation: 2,
                                                shadowColor: calendar.color.withValues(alpha: 0.4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            PopupMenuButton<int>(
                                              icon: Icon(Icons.calendar_month, color: calendar.color),

                                              onSelected: (days) {
                                                HapticFeedback.selectionClick();
                                                setState(() {
                                                  calendar.daysToShow = days;
                                                  _saveCalendars();
                                                });
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: 30, child: Text('30 Days')),
                                                const PopupMenuItem(value: 60, child: Text('60 Days')),
                                                const PopupMenuItem(value: 180, child: Text('180 Days')),
                                                const PopupMenuItem(value: 365, child: Text('365 Days')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 120,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              for (final weekday in _weekdays)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 1),
                                                  child: SizedBox(
                                                    height: 16,
                                                    child: Text(
                                                      weekday[0],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ActivityCalendar(
                                              activities: activityList,
                                              fromColor: scheme.surfaceContainerHighest,
                                              toColor: calendar.color,
                                              steps: 5,
                                              spacing: 3,
                                              borderRadius: BorderRadius.circular(3),
                                              weekday: _sharedWeekday(context),
                                              scrollDirection: _sharedOrientation(context),
                                              reverse: _sharedOrientation(context) == Axis.horizontal,
                                              tooltipBuilder: TooltipBuilder.rich(
                                                decoration: BoxDecoration(
                                                  color: scheme.inverseSurface,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                builder: (i) => TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${activityList[i]} ${activityList[i] == 1 ? 'activity' : 'activities'}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: scheme.onInverseSurface,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          ' on ${_tooltipFormat.format(_today.subtract(Duration(days: i)))}',
                                                      style: TextStyle(
                                                        color: scheme.onInverseSurface.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipPath(
              clipper: M3EClipper(Shapes.arch),
              child: Container(
                width: 96,
                height: 96,
                color: scheme.primaryContainer,
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Trackers Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first activity calendar to start tracking your daily habits and goals GitHub-style.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            M3EButton(
              size: M3EButtonSize.lg,
              onPressed: _addNewCalendar,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Create Tracker'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SharedAppData section

final Object _daysCountKey = Object();
final Object _weekdayKey = Object();
final Object _orientationKey = Object();

int _sharedDaysCount(BuildContext context) => SharedAppData.getValue(
      context,
      _daysCountKey,
      () => 365,
    );

int _sharedWeekday(BuildContext context) => SharedAppData.getValue(
      context,
      _weekdayKey,
      () => DateTime.now().weekday,
    );

Axis _sharedOrientation(BuildContext context) => SharedAppData.getValue(
      context,
      _orientationKey,
      () => Axis.horizontal,
    );
