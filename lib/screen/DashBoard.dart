import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namyong_demo/Component/bottom_nav.dart';
import 'package:namyong_demo/model/Work.dart';
import 'package:namyong_demo/screen/Stats.dart';
import 'package:namyong_demo/screen/login.dart';
import 'package:namyong_demo/screen/profile.dart';
import 'package:namyong_demo/screen/test_noti_page.dart';
import 'package:namyong_demo/screen/work_status/allwork2.dart';
import 'package:namyong_demo/screen/work_status/cancel_work.dart';
import 'package:namyong_demo/screen/work_status/finish_work.dart';
import 'package:namyong_demo/screen/work_status/onprocess_work.dart';
import 'package:namyong_demo/screen/work_status/waiting_work.dart';
import 'package:namyong_demo/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String _firstName = '';
  late String _lastName = '';
  late String role = '';
  int _currentIndex = 0;
  bool hasNotification = false; 
  

  @override
  void initState() {
    super.initState();
    _loadUserData();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
      setState(() {
        hasNotification = true; // Set the flag when a notification is opened
      });
    });

    // Check initial message if the app was opened from a terminated state
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      setState(() {
        hasNotification = true; 
        AlarmNotificationService.showNewWorkNotification(
          'You have new work assigned:',
        );// Set the flag if a notification opened the app
      });
    }
  }

  

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Employee')
            .doc(user.uid)
            .get();
        setState(() {
          _firstName = userData['Firstname'];
          _lastName = userData['Lastname'];
          role = userData['Role'];
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _signOut() async {
    // Clear SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Optionally, sign out from FirebaseAuth
    await FirebaseAuth.instance.signOut();

    // Navigate back to the LoginPage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 30, 62),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        toolbarHeight: 100,
        title: Shimmer.fromColors(
          baseColor: Colors.white,
          highlightColor: Colors.blue,
          child: Text(
            "Welcome",
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  '$_firstName\nRole: $role',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.person_alt_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    // Show the popup menu
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(1000, 80, 0, 1000),
                      items: [
                        const PopupMenuItem(
                          child: Text('Profile'), // Profile menu item
                          value: 'profile',
                        ),
                        const PopupMenuItem(
                          child: Text('Statics'), // Profile menu item
                          value: 'Statics',
                        ),
                        const PopupMenuItem(
                          child: Text('Logout'),
                          value: 'logout',
                        ),
                        const PopupMenuItem(
                          child: Text('Admin'),
                          value: 'Admin',
                        ),
                      ],
                      elevation: 8.0,
                    ).then((value) {
                      if (value == 'profile') {
                        // Redirect to profile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(user: FirebaseAuth.instance.currentUser),
                          ),
                        );
                      } else if (value == 'Statics') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StatsPage()),
                        );
                      } else if (value == 'logout') {
                        _signOut();
                      } else if (value == 'Admin') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TestNotiPage()),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(224, 14, 94, 253),
                Color.fromARGB(255, 4, 6, 126),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/—Pngtree—a blue wallpaper with white_15428175.jpg"), // path to your image
            fit: BoxFit.cover, // adjust as needed
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 2.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('works').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            int totalWorkCount = docs.where((doc) {
              var workData = doc.data() as Map<String, dynamic>;
              return (workData['dispatcherID'] == _firstName ||
                      workData['employeeId'] == _firstName ||
                      workData['GateoutID'] == _firstName);
            }).length;

            int completeWorkCount = docs.where((doc) {
              var workData = doc.data() as Map<String, dynamic>;
              Work work = Work.fromMap(workData);
              String lastStatus = work.statuses.isNotEmpty ? work.statuses.last : 'NoStatus';
              return lastStatus == 'Complete' && (workData['dispatcherID'] == _firstName ||
                      workData['employeeId'] == _firstName ||
                      workData['GateoutID'] == _firstName);
            }).length;

            int on_WorkCount = docs.where((doc) {
              var workData = doc.data() as Map<String, dynamic>;
              Work work = Work.fromMap(workData);
              String lastStatus = work.statuses.isNotEmpty ? work.statuses.last : 'NoStatus';
              return lastStatus == 'Assigned' && (workData['dispatcherID'] == _firstName ||
                      workData['employeeId'] == _firstName ||
                      workData['GateoutID'] == _firstName);
            }).length;

            int cancelWorkCount = docs.where((doc) {
              var workData = doc.data() as Map<String, dynamic>;
              Work work = Work.fromMap(workData);
              String lastStatus = work.statuses.isNotEmpty ? work.statuses.last : 'NoStatus';
              return lastStatus == 'Cancel' && (workData['dispatcherID'] == _firstName ||
                      workData['employeeId'] == _firstName ||
                      workData['GateoutID'] == _firstName);
            }).length;

            int waitingWorkCount = docs.where((doc) {
              var workData = doc.data() as Map<String, dynamic>;
              Work work = Work.fromMap(workData);
              String lastStatus = work.statuses.isNotEmpty ? work.statuses.last : 'NoStatus';
              return (lastStatus == 'Waiting' || lastStatus == 'NoStatus') && (workData['dispatcherID'] == _firstName ||
                      workData['employeeId'] == _firstName ||
                      workData['GateoutID'] == _firstName);
            }).length;

            return ListView(
              children: <Widget>[
                makeDashboardItem("Total Work", CupertinoIcons.doc_text_fill, totalWorkCount),
                makeDashboardItem("On-progress Work", CupertinoIcons.car_detailed, on_WorkCount),
                makeDashboardItem("Complete Work", CupertinoIcons.checkmark_alt_circle, completeWorkCount),
                makeDashboardItem("Cancel Work", CupertinoIcons.clear_fill, cancelWorkCount),
                makeDashboardItem("Waiting Work", CupertinoIcons.hourglass, waitingWorkCount),
              ],
            );
          },
        ),
      ),
    );
  }

  Card makeDashboardItem(String title, IconData icon, int count) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 4, 6, 126),
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to different pages based on the title
            if (title == "Total Work") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllWorkPage()),
              );
            } else if (title == "On-progress Work") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnProgressWorkPage(),
                ),
              );
            } else if (title == "Complete Work") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FinishWorkPage()),
              );
            } else if (title == "Cancel Work") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CancelWorkPage()),
              );
            } else if (title == "Waiting Work") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WaitingWorkPage()),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 40.0, color: Colors.white),
                SizedBox(width: 20.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5.0),
                    Text(
                      '$count',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
