import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:flutter/material.dart';
import 'utils.dart';

class AskingInput extends StatefulWidget {
  final bool isEdit;
  final int? sessionId;
  const AskingInput({super.key, required this.isEdit, required this.sessionId});

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
        backgroundColor: const Color(0xFF10131A),
        title: Text(
          widget.isEdit ? "Edit Session" : "New Session",
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      backgroundColor: const Color(0xFF0B0D14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF11151F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF263046)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Select your academic session range",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: sessionName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: "Enter Session Name",
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select by date',
                          style: TextStyle(
                            color: _selectedOption == DateSelectionOption.byDate
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Radio<DateSelectionOption>(
                        activeColor: const Color(0xFF4FC3F7),
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
                      Expanded(
                        child: Text(
                          'Select by month',
                          style: TextStyle(
                            color:
                                _selectedOption == DateSelectionOption.byMonth
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Radio<DateSelectionOption>(
                        activeColor: const Color(0xFF4FC3F7),
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
                  const SizedBox(height: 16),
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
                          pickedStart.year,
                          pickedStart.month,
                          1,
                        );
                      },
                      initialStart: globalStart,
                      initialEnd: globalEnd,
                      onEnd: (pickedEnd) {
                        globalEnd = DateTime(
                          pickedEnd.month == 12
                              ? pickedEnd.year + 1
                              : pickedEnd.year,
                          pickedEnd.month == 12 ? 1 : pickedEnd.month + 1,
                          0,
                        );
                      },
                    ),
                  const SizedBox(height: 22),
                  _buildNumericInput(
                    controller: workingDays,
                    label: 'Working days per week',
                  ),
                  const SizedBox(height: 16),
                  _buildNumericInput(
                    controller: classesPerDay,
                    label: 'Classes/Lectures per day',
                  ),
                  const SizedBox(height: 16),
                  _buildNumericInput(
                    controller: targetAt,
                    label: 'Target attendance (%)',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      final newDays = int.tryParse(workingDays.text);
                      final newTarget = double.tryParse(targetAt.text);
                      final perDay = int.tryParse(classesPerDay.text);
                      final sesName = sessionName.text;

                      if (globalStart == null || globalEnd == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select date range"),
                          ),
                        );
                        return;
                      }

                      if (newDays == null || newDays < 1 || newDays > 7) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Working days must be between 1–7"),
                          ),
                        );
                        return;
                      }

                      if (newTarget == null ||
                          newTarget < 1 ||
                          newTarget > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Target % must be 1–100"),
                          ),
                        );
                        return;
                      }

                      if (perDay == null || perDay < 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Classes per day must be at least 1"),
                          ),
                        );
                        return;
                      }

                      if (sesName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Session name cannot be empty"),
                          ),
                        );
                        return;
                      }

                      if (widget.isEdit) {
                        await IoFunctions.classesPerDay(
                          widget.sessionId!,
                          perDay,
                        );
                        await IoFunctions.updateSession(
                          widget.sessionId,
                          globalStart!,
                          globalEnd!,
                          newDays,
                          newTarget,
                          sesName,
                        );
                      } else {
                        await IoFunctions.createSession(
                          globalStart!,
                          globalEnd!,
                          newDays,
                          newTarget,
                          sesName,
                          perDay,
                        );
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(
                      widget.isEdit ? "Update Session" : "Create Session",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Generate your academic calendar for the selected range.",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericInput({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter value'),
        ),
      ],
    );
  }
}
