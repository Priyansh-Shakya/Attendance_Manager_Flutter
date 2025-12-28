import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:flutter/material.dart';
import 'utils.dart';

class AskingInput extends StatefulWidget {
  final bool isEdit;
  final int? sessionId;
  const AskingInput({Key? key, required this.isEdit, required this.sessionId})
      : super(key: key);

  @override
  State<AskingInput> createState() => _AskingInputState();
}

enum DateSelectionOption { byDate, byMonth }

class _AskingInputState extends State<AskingInput> {
  DateTime? globalStart;
  DateTime? globalEnd;
  int? globalWorkingDays;
  double? targetAttendance;
  String? globalSessionName;

  DateSelectionOption? _selectedOption = DateSelectionOption.byDate;

  final TextEditingController workingDays = TextEditingController();
  final TextEditingController targetAt = TextEditingController();
  final TextEditingController classesPerDay = TextEditingController();
  final TextEditingController sessionName = TextEditingController();

  void getClassesPerDay() async {}

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      final session = IoFunctions.getSessionAt(widget.sessionId!);
      if (session != null) {
        workingDays.text = session.activeDaysPerWeek.toString();
        targetAt.text = session.targetAttendance.toString();
        globalStart = session.sessionStart;
        globalEnd = session.sessionEnd;
        sessionName.text = session.sessionName;
      }
      _loadClassesPerDay();
    }
  }

  Future<void> _loadClassesPerDay() async {
    final perDay = await IoFunctions.loadClassesPerDay(widget.sessionId!);
    if (perDay != null) {
      classesPerDay.text = perDay.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Select Schedule Duration",
            style: TextStyle(color: Colors.green, fontSize: 22),
          ),
          centerTitle: true,
        ),
        backgroundColor: Color(0xff575656),
        body: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.95,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Card(
              elevation: 15,
              color: Colors.white,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Select your Academic Session range.",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black12, // background color
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: sessionName,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Enter Session Name",
                            hintStyle: TextStyle(color: Colors.black54),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors
                                    .grey, // border color when not focused
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.blue, // border color when focused
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select by date (e.g. 01/01/20xx - 01/01/20xx)',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                          Radio<DateSelectionOption>(
                            value: DateSelectionOption.byDate,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select by month (e.g. January - December)',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                          Radio<DateSelectionOption>(
                            value: DateSelectionOption.byMonth,
                            groupValue: _selectedOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_selectedOption == DateSelectionOption.byDate)
                        RangeInput(
                          label: "Input by date",
                          useMonthPicker: false,
                          initialStart: globalStart,
                          initialEnd: globalEnd,
                          onStart: (pickedStart) => globalStart = pickedStart,
                          onEnd: (pickedEnd) => globalEnd = pickedEnd,
                        ),

                      if (_selectedOption == DateSelectionOption.byMonth)
                        RangeInput(
                          label: "Input by month",
                          useMonthPicker: true,
                          onStart: (pickedStart) {
                            globalStart = DateTime(
                                pickedStart.year, pickedStart.month, 1);
                          },
                          initialStart: globalStart,
                          initialEnd: globalEnd,
                          onEnd: (pickedEnd) {
                            globalEnd = DateTime(
                              pickedEnd.month == 12
                                  ? pickedEnd.year + 1
                                  : pickedEnd.year,
                              pickedEnd.month == 12 ? 1 : pickedEnd.month + 1,
                              0, // Last day of the previous month
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Flexible(
                            flex: 3,
                            child: Text(
                              'Enter number of working days per week.',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            flex: 1,
                            child: TextField(
                              controller: workingDays,
                              style: TextStyle(color: Colors.black),
                              maxLines: 1,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Flexible(
                            flex: 3,
                            child: Text(
                              'Enter number of Classes/Lectures per day.',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            flex: 1,
                            child: TextField(
                              controller: classesPerDay,
                              style: TextStyle(color: Colors.black),
                              maxLines: 1,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Flexible(
                            flex: 3,
                            child: Text(
                              'Enter your target attendance percentage.',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            flex: 1,
                            child: TextField(
                              controller: targetAt,
                              style: TextStyle(color: Colors.black),
                              maxLines: 1,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Generate button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffe4eef6),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final newDays = int.tryParse(workingDays.text);
                          final newTarget = double.tryParse(targetAt.text);
                          final perDay = int.tryParse(classesPerDay.text);
                          final sesName = sessionName.text;

                          if (globalStart == null || globalEnd == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please select date range")),
                            );
                            return;
                          }

                          if (newDays == null || newDays < 1 || newDays > 7) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Working days must be between 1–7")),
                            );
                            return;
                          }

                          if (newTarget == null ||
                              newTarget < 1 ||
                              newTarget > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Target % must be 1–100")),
                            );
                            return;
                          }

                          if (perDay == null || perDay < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Classes per day must be at least 1")),
                            );
                            return;
                          }

                          if (sesName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Session name cannot be empty")),
                            );
                            return;
                          }

                          if (widget.isEdit) {
                            print("Edit worked");
                            await IoFunctions.classesPerDay(
                                widget.sessionId!, perDay);
                            await IoFunctions.updateSession(
                              widget.sessionId,
                              globalStart!,
                              globalEnd!,
                              newDays,
                              newTarget,
                              sesName,
                            );
                          } else {
                            print("Create worked");

                            await IoFunctions.createSession(
                                globalStart!,
                                globalEnd!,
                                newDays,
                                newTarget,
                                sesName,
                                perDay);
                          }

                          debugPrint("On Pressed clicked ✅");
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: widget.isEdit
                            ? const Text("Update",
                                style: TextStyle(
                                    color: Colors.green, fontSize: 18))
                            : const Text("Generate",
                                style: TextStyle(
                                    color: Colors.green, fontSize: 18)),
                      ),

                      const SizedBox(height: 3),
                      const Text(
                        "(Generate your Academic Calendar for selected range.)",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontStyle: FontStyle.normal,
                        ),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
