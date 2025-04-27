import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceManager()),
      ],
      child: AttendifyPlus(),
    ),
  );
}

class AttendifyPlus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify Plus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RoleSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final DateTime date;
  final bool isPresent;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.isPresent,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      studentId: map['studentId'],
      studentName: map['studentName'],
      date: DateTime.parse(map['date']),
      isPresent: map['isPresent'],
    );
  }
}

class AttendanceManager extends ChangeNotifier {
  List<AttendanceRecord> _records = [];
  List<String> _students = [];
  DateTime _selectedDate = DateTime.now();

  List<AttendanceRecord> get records => _records;
  List<String> get students => _students;
  DateTime get selectedDate => _selectedDate;

  AttendanceManager() {
    _loadData();
    _initializeDemoStudents();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsData = prefs.getStringList('attendanceRecords');

    if (recordsData != null) {
      _records = recordsData
          .map((e) => AttendanceRecord.fromMap(json.decode(e)))
          .toList();
    }

    final studentsData = prefs.getStringList('students');
    if (studentsData != null) {
      _students = studentsData;
    }

    notifyListeners();
  }

  void _initializeDemoStudents() {
    if (_students.isEmpty) {
      _students = [
        'Arun (ID: S1001)',
        'Chetan Singh (ID: S1002)',
        'Sneha Singh Besan(ID: S1003)',
        'Ananya (ID: S1004)',
        'Tanishka (ID: S1005)'
      ];
      _saveStudents();
    }
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('attendanceRecords',
        _records.map((e) => json.encode(e.toMap())).toList());
  }

  Future<void> _saveStudents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('students', _students);
  }

  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void markAttendance(String studentId, String studentName, bool isPresent) {
    _records.removeWhere((r) =>
        r.studentId == studentId && DateUtils.isSameDay(r.date, _selectedDate));

    _records.add(AttendanceRecord(
      studentId: studentId,
      studentName: studentName,
      date: _selectedDate,
      isPresent: isPresent,
    ));

    _saveRecords();
    notifyListeners();
  }

  Map<String, dynamic> getStudentAttendance(String studentId) {
    final studentRecords =
        _records.where((r) => r.studentId == studentId).toList();
    final presentCount = studentRecords.where((r) => r.isPresent).length;
    final totalClasses = studentRecords.length;
    final percentage =
        totalClasses > 0 ? (presentCount / totalClasses * 100) : 0;

    return {
      'present': presentCount,
      'total': totalClasses,
      'percentage': percentage,
      'records': studentRecords,
    };
  }

  bool? getAttendanceStatus(String studentId, DateTime date) {
    try {
      return _records
          .firstWhere((r) =>
              r.studentId == studentId && DateUtils.isSameDay(r.date, date))
          .isPresent;
    } catch (e) {
      return null;
    }
  }

  void addStudent(String name, String id) {
    _students.add('$name (ID: $id)');
    _saveStudents();
    notifyListeners();
  }
}

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: 1.2,
                duration: Duration(seconds: 1),
                curve: Curves.elasticOut,
                child: Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Attendify Plus',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 40),
              AnimatedButton(
                text: 'Teacher Portal',
                onPressed: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => TeacherDashboard(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              AnimatedButton(
                text: 'Student Portal',
                onPressed: () => _showStudentLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentLogin(BuildContext context) {
    final manager = Provider.of<AttendanceManager>(context, listen: false);
    final studentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Student Login', style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your Student ID (e.g., S1001)',
                style: TextStyle(color: Colors.black87)),
            TextField(
              controller: studentIdController,
              decoration: InputDecoration(
                hintText: 'Student ID',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child:
                Text('View Attendance', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (manager.students
                  .any((s) => s.contains(studentIdController.text))) {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StudentDashboard(
                            studentId: studentIdController.text)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid Student ID')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedButton({required this.text, required this.onPressed});

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<AttendanceManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Teacher Dashboard - ${DateFormat('MMM d, y').format(manager.selectedDate)}',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: Colors.white),
            onPressed: () => manager.updateSelectedDate(DateTime.now()),
          ),
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _showAddStudentDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE4E7EB),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildCalendar(context),
            Expanded(child: _buildAttendanceList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final manager = Provider.of<AttendanceManager>(context);

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 0,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: manager.selectedDate,
            selectedDayPredicate: (day) =>
                DateUtils.isSameDay(manager.selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              manager.updateSelectedDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarFormat: _calendarFormat,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              formatButtonDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              formatButtonTextStyle: TextStyle(color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.black87),
              weekendTextStyle: TextStyle(color: Colors.black87),
              holidayTextStyle: TextStyle(color: Colors.black87),
              outsideTextStyle: TextStyle(color: Colors.grey),
              disabledTextStyle: TextStyle(color: Colors.grey[400]),
              todayDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF6A11CB),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context) {
    final manager = Provider.of<AttendanceManager>(context);
    final date = manager.selectedDate;

    return ListView.builder(
      itemCount: manager.students.length,
      itemBuilder: (context, index) {
        final studentInfo = manager.students[index];
        final studentId = studentInfo.split('(ID: ')[1].replaceAll(')', '');
        final studentName = studentInfo.split(' (ID:')[0];
        final attendanceStatus = manager.getAttendanceStatus(studentId, date);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                studentName,
                style: TextStyle(color: Colors.black87),
              ),
              subtitle: Text(
                studentId,
                style: TextStyle(color: Colors.black54),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check,
                        color: attendanceStatus == true
                            ? Colors.green
                            : Colors.grey),
                    onPressed: () =>
                        manager.markAttendance(studentId, studentName, true),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: attendanceStatus == false
                            ? Colors.red
                            : Colors.grey),
                    onPressed: () =>
                        manager.markAttendance(studentId, studentName, false),
                  ),
                ],
              ),
              tileColor: attendanceStatus == null
                  ? null
                  : attendanceStatus
                      ? Colors.green[50]
                      : Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => _showStudentDetails(context, studentId, studentName),
            ),
          ),
        );
      },
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final manager = Provider.of<AttendanceManager>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Student', style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Student Name',
                labelStyle: TextStyle(color: Colors.black87),
              ),
              style: TextStyle(color: Colors.black),
            ),
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: 'Student ID',
                labelStyle: TextStyle(color: Colors.black87),
              ),
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Add', style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  idController.text.isNotEmpty) {
                manager.addStudent(nameController.text, idController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(
      BuildContext context, String studentId, String studentName) {
    final manager = Provider.of<AttendanceManager>(context, listen: false);
    final attendance = manager.getStudentAttendance(studentId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$studentName Attendance',
            style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Attendance: ${attendance['percentage'].toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: attendance['percentage'] / 100,
              backgroundColor: Colors.grey[200],
              color: _getPercentageColor(attendance['percentage']),
            ),
            SizedBox(height: 10),
            Text(
              'Present: ${attendance['present']}/${attendance['total']}',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              'Attendance History:',
              style: TextStyle(color: Colors.black87),
            ),
            SizedBox(height: 5),
            Container(
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: attendance['records'].length,
                itemBuilder: (context, index) {
                  final record = attendance['records'][index];
                  return ListTile(
                    title: Text(
                      DateFormat('MMM d, y').format(record.date),
                      style: TextStyle(color: Colors.black87),
                    ),
                    trailing: record.isPresent
                        ? Icon(Icons.check, color: Colors.green)
                        : Icon(Icons.close, color: Colors.red),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage > 85) return Colors.green;
    if (percentage > 60) return Colors.blue;
    if (percentage > 40) return Colors.orange;
    return Colors.red;
  }
}

class StudentDashboard extends StatelessWidget {
  final String studentId;

  const StudentDashboard({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<AttendanceManager>(context);
    final studentInfo =
        manager.students.firstWhere((s) => s.contains(studentId));
    final studentName = studentInfo.split(' (ID:')[0];
    final attendance = manager.getStudentAttendance(studentId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$studentName Attendance',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE4E7EB),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'Your Attendance',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),
                    AnimatedCircularProgressIndicator(
                      percentage: attendance['percentage'],
                      present: attendance['present'],
                      total: attendance['total'],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Recent Attendance:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: attendance['records'].length,
                  itemBuilder: (context, index) {
                    final record = attendance['records'][index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          DateFormat('MMMM d, y').format(record.date),
                          style: TextStyle(color: Colors.black87),
                        ),
                        trailing: record.isPresent
                            ? Icon(Icons.check, color: Colors.green)
                            : Icon(Icons.close, color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedCircularProgressIndicator extends StatefulWidget {
  final double percentage;
  final int present;
  final int total;

  const AnimatedCircularProgressIndicator({
    required this.percentage,
    required this.present,
    required this.total,
  });

  @override
  _AnimatedCircularProgressIndicatorState createState() =>
      _AnimatedCircularProgressIndicatorState();
}

class _AnimatedCircularProgressIndicatorState
    extends State<AnimatedCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 10,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                ),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: 10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getPercentageColor(widget.percentage)),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(_animation.value * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${widget.present}/${widget.total}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage > 85) return Colors.green;
    if (percentage > 60) return Colors.blue;
    if (percentage > 40) return Colors.orange;
    return Colors.red;
  }
}
