import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


import 'data/models/stop_group.dart';
import 'data/database/app_database.dart';
import 'data/models/stop.dart';
import 'features/map/map_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/profile_screen.dart';
import 'features/home/home_screen.dart';
import 'data/services/stop_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await StopSyncService.syncIfNeeded();
  } catch (e) {
    print('Sync zlyhal: $e');
  }



  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final pages = [
    const HomeScreen(),
    const SearchScreen(),
    const MapScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final fromController = TextEditingController();
  final toController = TextEditingController();

  List<StopGroup> fromResults = [];
  List<StopGroup> toResults = [];

  Stop? selectedFrom;
  Stop? selectedTo;

  int _fromSearchVersion = 0;
  int _toSearchVersion = 0;

  // ================= FROM SEARCH =================

  void searchFrom(String query) async {
    final searchVersion = ++_fromSearchVersion;

    selectedFrom = null;

    if (query.isEmpty) {
      setState(() => fromResults = []);
      return;
    }

    final results = await AppDatabase.searchStopsGrouped(query);

    if (!mounted || searchVersion != _fromSearchVersion) return;

    setState(() {
      fromResults = results;
    });
  }

  // ================= TO SEARCH =================

  void searchTo(String query) async {
    final searchVersion = ++_toSearchVersion;

    selectedTo = null;

    if (query.isEmpty) {
      setState(() => toResults = []);
      return;
    }

    final results = await AppDatabase.searchStopsGrouped(query);

    if (!mounted || searchVersion != _toSearchVersion) return;

    setState(() {
      toResults = results;
    });
  }

  // ================= SEARCH BUTTON =================

  void searchRoute() {
    print("FROM: ${selectedFrom?.stopName}");
    print("TO: ${selectedTo?.stopName}");
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search connection")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ======================================================
            // FROM INPUT
            // ======================================================
            TextField(
              controller: fromController,
              onChanged: searchFrom,
              decoration: const InputDecoration(
                labelText: "From",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trip_origin),
              ),
            ),

            if (fromResults.isNotEmpty)
              Container(
                height: 250,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: fromResults.length,
                  itemBuilder: (context, index) {
                    final group = fromResults[index];
                    final stop = group.stops.first;

                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(group.name),
                      subtitle: const Text("MHD Praha"),
                      onTap: () {
                        setState(() {
                          selectedFrom = stop;
                          fromController.text = group.name;
                          fromController.selection = TextSelection.collapsed(
                            offset: group.name.length,
                          );
                          fromResults = [];
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // ======================================================
            // TO INPUT
            // ======================================================
            TextField(
              controller: toController,
              onChanged: searchTo,
              decoration: const InputDecoration(
                labelText: "To",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            if (toResults.isNotEmpty)
              Container(
                height: 250,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: toResults.length,
                  itemBuilder: (context, index) {
                    final group = toResults[index];
                    final stop = group.stops.first;

                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(group.name),
                      subtitle: const Text("MHD Praha"),
                      onTap: () {
                        setState(() {
                          selectedTo = stop;
                          toController.text = group.name;
                          toController.selection = TextSelection.collapsed(
                            offset: group.name.length,
                          );
                          toResults = [];
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // ======================================================
            // SEARCH BUTTON
            // ======================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: searchRoute,
                child: const Text(
                  "Search route",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  final String from;
  final String to;
  final List<String> results;

  const ResultsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$from → $to")),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.directions_bus),
            title: Text(results[index]),
          );
        },
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Notifications"));
  }
}

