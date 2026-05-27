import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:attendance_manager/Date-Month-Input/askingInput.dart';
import 'package:attendance_manager/settingsNnotifications/settings.dart';
import 'package:attendance_manager/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onSessionSelected;
  const HomeScreen({super.key, required this.onSessionSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? selectedSessionID;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final savedId = await IoFunctions.loadSelectedSession();
    setState(() {
      selectedSessionID = savedId;
    });
    if (savedId != null) {
      widget.onSessionSelected(savedId);
    }
    debugPrint("ID: $selectedSessionID");
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final Box<SessionData> sessions = Hive.box<SessionData>("SessionBoxV3");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10131A),
        actions: [
          IconButton(
            onPressed: () async {
              final latestId = await IoFunctions.loadSelectedSession();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(sessionId: latestId),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
        title: const Text(
          "Attendance Manager",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF0B0D14),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161B2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2F3650)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sessions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Manage your academic sessions with a clean, modern dashboard.",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: sessions.listenable(),
                builder: (context, Box<SessionData> box, _) {
                  if (box.isEmpty) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121825),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2C3348)),
                        ),
                        child: const Text(
                          "No session yet. Create a new one to get started.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final session = box.getAt(index)!;
                      final id = box.keyAt(index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSessionID = id;
                            widget.onSessionSelected(id);
                          });
                          IoFunctions.saveSelectedSession(id);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: selectedSessionID == id
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFF1C2336),
                              width: 1.2,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                          elevation: 3,
                          color: const Color(0xFF121825),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            leading: CircleAvatar(
                              maxRadius: 18,
                              backgroundColor: const Color(0xFF4FC3F7),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(
                              session.sessionName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${formatDate(session.sessionStart)} • ${formatDate(session.sessionEnd)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Created on ${formatDate(session.creationDate)}",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AskingInput(
                                          isEdit: true,
                                          sessionId: id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF4FC3F7),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Color(0xFFEF5350),
                                  ),
                                  onPressed: () async {
                                    Vibration.selectAll();
                                    await IoFunctions.deleteSessionAt(index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEF5350),
        onPressed: () {
          Vibration.buttonPress();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AskingInput(sessionId: null, isEdit: false),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 25),
      ),
    );
  }
}
