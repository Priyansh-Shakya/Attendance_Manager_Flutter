import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:attendance_manager/Date-Month-Input/askingInput.dart';
import 'package:attendance_manager/settingsNnotifications/settings.dart';
import 'package:attendance_manager/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onSessionSelected;
  const HomeScreen({Key? key, required this.onSessionSelected})
      : super(key: key);

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
    print("ID: $selectedSessionID");
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
        backgroundColor: const Color(0xff141414),
        actions: [
          IconButton(
            onPressed: () async {
              final latestId = await IoFunctions.loadSelectedSession();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Settings(
                    sessionId: latestId,
                  ),
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
        centerTitle: true,
      ),
      backgroundColor: const Color(0xff2e2e2e),

      /// This makes it rebuild when Hive box changes
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Sessions:",
                  style: TextStyle(color: Colors.white, fontSize: 25)),
            ),
            SizedBox(
              height: 5,
            ),
            ValueListenableBuilder(
              valueListenable: sessions.listenable(),
              builder: (context, Box<SessionData> box, _) {
                if (box.isEmpty) {
                  return const Expanded(
                      child: Center(
                    child: Text(
                      "No Session yet. Create new",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ));
                }

                return Expanded(
                    child: ListView.builder(
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
                          print("Gesture id: $selectedSessionID");
                          IoFunctions.saveSelectedSession(id);
                        },
                        child: Card(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: selectedSessionID == id
                                    ? Colors.red
                                    : const Color(0xff000000), // Border color
                                width: 1.5, // Border width
                              ),
                              borderRadius: BorderRadius.circular(
                                  16), // Optional: rounded corners
                            ),
                            elevation: 10,
                            color: const Color(0xff000000),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                maxRadius: 14,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                              title: Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  session.sessionName,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${formatDate(session.sessionStart)} - ${formatDate(session.sessionEnd)}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    "Created on: ${formatDate(session.creationDate)}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AskingInput(
                                            isEdit: true,
                                            sessionId:
                                                id, // Use the current session's id
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      Vibration.selectAll(); //heavy vibration
                                      await IoFunctions.deleteSessionAt(index);
                                    },
                                  ),
                                ],
                              ),
                            )));
                  },
                ));
              },
            ),
          ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Vibration.buttonPress(); //medium
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AskingInput(
                      sessionId: null,
                      isEdit: false,
                    )),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}
