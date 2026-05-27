import 'package:flutter/material.dart';

class RangeInput extends StatefulWidget {
  final String label;
  final bool useMonthPicker; // true = month, false = date
  final DateTime? initialStart;
  final DateTime? initialEnd;

  final void Function(DateTime)? onStart;
  final void Function(DateTime)? onEnd;

  const RangeInput({
    super.key,
    required this.label,
    this.useMonthPicker = false,
    this.onEnd,
    this.onStart,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<RangeInput> createState() => _RangeInputState();
}

class _RangeInputState extends State<RangeInput> {
  DateTime? start;
  DateTime? end;

  @override
  void initState() {
    super.initState();
    start = widget.initialStart;
    end = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.label, style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xffe4eef6,
                ), // your desired background color
                foregroundColor:
                    Colors.black, // text color - you had black text, keep it
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    start = picked;
                  });
                  if (widget.onStart != null) {
                    widget.onStart?.call(picked);
                  }
                }
              },
              child: Text(
                start == null
                    ? "Starting  ${widget.useMonthPicker ? "Month" : "Date"}"
                    : widget.useMonthPicker
                    ? _formatMonth(start!)
                    : _formatDate(start!),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xffe4eef6,
                ), // your desired background color
                foregroundColor:
                    Colors.black, // text color - you had black text, keep it
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    end = picked;
                  });
                  if (widget.onEnd != null) {
                    widget.onEnd?.call(picked);
                  }
                }
              },
              child: Text(
                end == null
                    ? "Ending  ${widget.useMonthPicker ? "Month" : "Date"}"
                    : widget.useMonthPicker
                    ? _formatMonth(end!)
                    : _formatDate(end!),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonth(DateTime date) {
    return "${_monthName(date.month)}  ${date.year}";
  }

  String _monthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}
