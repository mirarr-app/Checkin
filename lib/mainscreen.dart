import 'package:Checkin/activity_calendar.dart';
import 'package:Checkin/custom_divider.dart';
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

  CalendarData(
      {required this.name,
      required this.activities,
      required this.color,
      required this.max});

  Map<String, dynamic> toJson() => {
        'name': name,
        'activities': activities,
        'color': color.value,
        'max': max
      };

  factory CalendarData.fromJson(Map<String, dynamic> json) => CalendarData(
        name: json['name'],
        activities: Map<String, int>.from(json['activities']),
        color:
            json['color'] != null ? Color(json['color'] as int) : Colors.orange,
        max: json['max'] != null ? json['max'] as int : 10,
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
          title: const Text(
            'Max Activities',
            style: TextStyle(color: Colors.orange),
          ),
          content: TextField(
            autocorrect: false,
            onChanged: (value) {
              // Parse the input string to an integer
              max = int.tryParse(value);
            },
            style: const TextStyle(
              color: Colors.black,
            ),
            cursorColor: Colors.black,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: Colors.orangeAccent[200],
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                // Only pop with a value if max is not null
                if (max != null) {
                  Navigator.of(context).pop(max);
                } else {
                  // Optionally, show an error message if no valid number was entered
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid number')),
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
          title: const Text(
            'New Calendar Name',
            style: TextStyle(color: Colors.orange),
          ),
          content: TextField(
            autocorrect: false,
            onChanged: (value) {
              name = value;
            },
            style: const TextStyle(
              color: Colors.black,
            ),
            cursorColor: Colors.black,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.orangeAccent[200],
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                Navigator.of(context).pop(name);
              },
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
          title: const Text('Delete Calendar',
              style: TextStyle(color: Colors.orange)),
          content: Text(
              'Are you sure you want to delete "${_calendars[index].name}"?',
              style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child:
                  const Text('Delete', style: TextStyle(color: Colors.orange)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
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
          title: const Text('Activity Calendars'),
          backgroundColor: Colors.orange,
          elevation: 3,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addNewCalendar,
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _calendars.length,
          itemBuilder: (context, index) {
            final calendar = _calendars[index];
            final activityList = _generateDateKeys(_sharedDaysCount(context))
                .map((key) => calendar.activities[key] ?? 0)
                .toList();

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                      child: Text(
                        calendar.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: calendar.color),
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(calendar.color)),
                            onPressed: () => _incrementToday(index),
                            child: const Text(
                              'Check in',
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: calendar.color),
                          onPressed: () => _deleteCalendar(index),
                        ),
                      ],
                    ),
                  ],
                ),
                const CustomDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: SizedBox(
                    height: 235,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            for (final weekday in _weekdays)
                              SizedBox(
                                height: 30,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                  child: Center(
                                    child: Text(
                                      weekday,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 208,
                                child: ActivityCalendar(
                                  activities: activityList,
                                  fromColor: Colors.grey[900],
                                  toColor: calendar.color,
                                  steps: calendar.max,
                                  spacing: 5,
                                  borderRadius: BorderRadius.circular(4),
                                  weekday: _sharedWeekday(context),
                                  scrollDirection: _sharedOrientation(context),
                                  reverse: _sharedOrientation(context) ==
                                      Axis.horizontal,
                                  tooltipBuilder: TooltipBuilder.rich(
                                    builder: (i) => TextSpan(children: [
                                      TextSpan(
                                        text:
                                            '${activityList[i]} ${activityList[i] > 0 ? 'times' : 'time'}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      TextSpan(
                                          text:
                                              ' on ${_tooltipFormat.format(_today.subtract(Duration(days: i)))}'),
                                    ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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


