import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showCustomDialog(
  BuildContext context, {
  required String title,
  required String screenNumber,
  String? content, // still support plain text
  Widget? customContent, // new: allow passing your own widget
}) async {
  final prefs = await SharedPreferences.getInstance();
  bool isSeen = prefs.getBool(screenNumber) ?? false;

  if (!isSeen) {
    showDialog(
      context: context,
      builder: ((_) => AlertDialog(
        scrollable: true,
        title: Text(title, textAlign: TextAlign.center),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: SingleChildScrollView(
            child:
                customContent ??
                Text(content ?? "", style: const TextStyle(fontSize: 15)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Ok"),
          ),
        ],
      )),
    );
    await prefs.setBool(screenNumber, true);
  }
}

void allClassesDailoge(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap a button to dismiss
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(children: <Widget>[Text(message)]),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss the dialog
            },
          ),
        ],
      );
    },
  );
}
