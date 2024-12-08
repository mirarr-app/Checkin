import 'package:Checkin/activity_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
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

  CalendarData(
      {required this.name,
      required this.activities,
      required this.color,
      required this.max,
      this.daysToShow = 365});

  Map<String, dynamic> toJson() => {
        'name': name,
        'activities': activities,
        'color': color.value,
        'max': max,
        'daysToShow': daysToShow
      };

  factory CalendarData.fromJson(Map<String, dynamic> json) => CalendarData(
        name: json['name'],
        activities: Map<String, int>.from(json['activities']),
        color:
            json['color'] != null ? Color(json['color'] as int) : Colors.orange,
        max: json['max'] != null ? json['max'] as int : 10,
        daysToShow: json['daysToShow'] ?? 365,
      );
}

class _MainScreenState extends State<MainScreen> {
  late Box<Map> _calendarsBox;
  List<CalendarData> _calendars = [];
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _calendarsBox = await Hive.openBox<Map>('calendars');
    _loadCalendars();
  }

  void _loadCalendars() {
    try {
      _calendars = _calendarsBox.values
          .map((e) => CalendarData.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (_calendars.isEmpty) {
        // Initialize with a default calendar if empty
        _calendars = [
          CalendarData(
            name: 'Calendar',
            activities: _createEmptyCalendar(),
            color: Colors.orange,
            max: 10,
            daysToShow: 365,
          )
        ];
        _saveCalendars();
      } else {
        // Ensure all calendars have up-to-date keys
        for (var calendar in _calendars) {
          _ensureDataShift(calendar.activities);
        }
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error loading calendars: $e');
      }
      // Handle the error, maybe reset to a default state
      _calendars = [
        CalendarData(
          name: 'Calendar',
          activities: _createEmptyCalendar(),
          color: Colors.orange,
          max: 10,
          daysToShow: 365,
        )
      ];
      _saveCalendars();
      setState(() {});
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
      // Today's key doesn't exist, shift the data
      final newActivities = <String, int>{};
      newActivities[todayKey] = 0; // Add today with 0 activity

      _generateDateKeys(_sharedDaysCount(context) - 1).forEach((dateKey) {
        newActivities[dateKey] = activities[dateKey] ?? 0;
      });

      activities.clear();
      activities.addAll(newActivities);
    }
  }

  Future<void> _addNewCalendar() async {
    String? name = await _showNameDialog();
    if (name != null && name.isNotEmpty) {
      int? max = await _showMaxDialog();
      Color? color = await _selectColor(context: context);
      if (color != null) {
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
      }
    }
  }

  Future<Color?> _selectColor({required BuildContext context}) async {
    final List<Color> colorOptions = [
      const Color.fromARGB(255, 255, 51, 36),
      const Color.fromARGB(255, 28, 153, 255),
      const Color.fromARGB(255, 36, 255, 43),
      const Color.fromARGB(255, 255, 234, 43),
      const Color.fromARGB(255, 222, 36, 255),
      const Color.fromARGB(255, 255, 166, 33),
      const Color.fromARGB(255, 255, 67, 130),
      const Color.fromARGB(255, 16, 255, 231),
    ];

    return showDialog<Color?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colorOptions.map((Color color) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(color);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int? max;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Daily Goal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            autofocus: true,
            autocorrect: false,
            onChanged: (value) => max = int.tryParse(value),
            style: const TextStyle(
              fontSize: 16,
            ),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter maximum daily activities',
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Set Goal'),
              onPressed: () {
                if (max != null) {
                  Navigator.of(context).pop(max);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showNameDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'New Calendar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            autofocus: true,
            autocorrect: false,
            onChanged: (value) => name = value,
            style: const TextStyle(
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter calendar name',
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create'),
              onPressed: () => Navigator.of(context).pop(name),
            ),
          ],
        );
      },
    );
  }

  void _incrementToday(int calendarIndex) {
    final todayKey = _dateFormat.format(_today);
    setState(() {
      _calendars[calendarIndex].activities[todayKey] =
          (_calendars[calendarIndex].activities[todayKey] ?? 0) + 1;
      _saveCalendars();
    });
  }

  Future<void> _deleteCalendar(int index) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete ${_calendars[index].name}?',
            style: TextStyle(
              color: _calendars[index].color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _calendars.removeAt(index);
        _saveCalendars();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Activity Calendars',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _addNewCalendar,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ListView.builder(
            itemCount: _calendars.length,
            itemBuilder: (context, index) {
              final calendar = _calendars[index];
              final activityList = _generateDateKeys(calendar.daysToShow)
                  .map((key) => calendar.activities[key] ?? 0)
                  .toList();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            calendar.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: calendar.color,
                            ),
                          ),
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: () => _incrementToday(index),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      calendar.color.withOpacity(0.2),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add,
                                        size: 18, color: calendar.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Check in',
                                      style: TextStyle(
                                          color: calendar.color,
                                          fontFamily: "RobotoMono"),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<int>(
                                icon: Icon(Icons.calendar_month,
                                    color: calendar.color),
                                onSelected: (days) {
                                  setState(() {
                                    calendar.daysToShow = days;
                                    _saveCalendars();
                                  });
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 30, child: Text('30 Days')),
                                  const PopupMenuItem(
                                      value: 60, child: Text('60 Days')),
                                  const PopupMenuItem(
                                      value: 180, child: Text('180 Days')),
                                  const PopupMenuItem(
                                      value: 365, child: Text('365 Days')),
                                ],
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: calendar.color),
                                onPressed: () => _deleteCalendar(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                        child: SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                            color: Colors.grey.withOpacity(0.8),
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
                                  fromColor: Colors.grey[850],
                                  toColor: calendar.color,
                                  steps: 5,
                                  spacing: 3,
                                  borderRadius: BorderRadius.circular(2),
                                  weekday: _sharedWeekday(context),
                                  scrollDirection: _sharedOrientation(context),
                                  reverse: _sharedOrientation(context) ==
                                      Axis.horizontal,
                                  tooltipBuilder: TooltipBuilder.rich(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                    ),
                                    builder: (i) => TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${activityList[i]} ${activityList[i] == 1 ? 'activity' : 'activities'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              ' on ${_tooltipFormat.format(_today.subtract(Duration(days: i)))}',
                                          style: TextStyle(
                                            color: Colors.grey[200],
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
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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

/// Helpful widgets


