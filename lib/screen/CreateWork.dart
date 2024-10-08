import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:namyong_demo/Component/bottom_nav.dart';
import 'package:namyong_demo/component/form_field.dart';
import 'package:namyong_demo/model/Work.dart';
import 'package:namyong_demo/screen/DashBoard.dart';
import 'package:namyong_demo/service/firebase_api.dart';
import 'package:namyong_demo/service/notification_service.dart';

class CreateWorkPage extends StatefulWidget {
  const CreateWorkPage({super.key});

  @override
  _CreateWorkPageState createState() => _CreateWorkPageState();
}

class _CreateWorkPageState extends State<CreateWorkPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String? currentUserID = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _consigneeController = TextEditingController();
  final TextEditingController _vesselController = TextEditingController();
  final TextEditingController _voyController = TextEditingController();
  final TextEditingController _blNoController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final LNotificationService notificationService = LNotificationService();

  String? _dispatcherID; // Variable to store dispatcherID
  String? _role;
  List<String> employees = [];
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  TimeOfDay? _estimatedCompletionTime;
  bool _isSignatureStamped = false;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
    _getDispatcherID();
    _loadRoleData();
  }

  void fetchEmployees() async {
    try {
      // Assuming 'Employee' is the name of the collection in Firestore
      QuerySnapshot employeeSnapshot = await FirebaseFirestore.instance
          .collection('Employee')
          .where('Role',
              isEqualTo: 'Checker') // Filter employees with role 'Checker'
          .get();
      setState(() {
        // Update the employees list with the data from Firestore
        employees = employeeSnapshot.docs
            .map((doc) => doc.get('Firstname'))
            .where((employee) => employee != null)
            .map((employee) => employee.toString())
            .toList();
        print(employees);
      });
    } catch (e) {
      print('Error fetching employees: $e');
    }
  }

  Future<void> _getDispatcherID() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Employee')
            .doc(user.uid)
            .get();
        setState(() {
          _dispatcherID = userData['Firstname'];
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadRoleData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Employee')
            .doc(user.uid)
            .get();
        setState(() {
          _role = userData['Role']; // Update user's role
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _getSignature() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('Employee')
            .doc(user.uid)
            .get();
        setState(() {
          _dispatcherID = userData['Signature'];
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> getImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void sendNotificationToUser(String firstName, String deviceToken) async {
    LNotificationService notificationService = LNotificationService();
    notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    int _currentIndex = 1;
    return _role == 'Dispatcher'
        ? Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              toolbarHeight: 100,
              title: const Text(
                "Create work page",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
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
            body: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  // Title above the form fields
                  const Text(
                    "WharfID (BL/No) เลขใบวาป",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20.0),
                  DefaultFormField(
                    hint: 'WharfID (BL/No)',
                    controller: _blNoController,
                    validText: 'Please enter a BL number',
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: 15.0),
                  const Text(
                    "Date-วันที่",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Date',
                      labelText: 'Date', // Optional label text
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: _dateController,
                    readOnly: true, // Set to true to prevent direct text input
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                      );

                      if (pickedDate != null) {
                        setState(() {
                          _dateController.text =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15.0),
                  const Text(
                    "Consignee",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  DefaultFormField(
                    hint: 'Consignee',
                    controller: _consigneeController,
                    validText: 'Please enter a consignee',
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: 15.0),
                  const Text(
                    "Vessel",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  DefaultFormField(
                    hint: 'Vessel',
                    controller: _vesselController,
                    validText: 'Please enter a vessel',
                  ),
                  const SizedBox(height: 15.0),
                  const Text(
                    "Voy",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  DefaultFormField(
                    hint: 'Voy',
                    controller: _voyController,
                    validText: 'Please enter a voyage number',
                  ),
                  const SizedBox(height: 15.0),
                  const Text(
                    "Shipping",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  DefaultFormField(
                    hint: 'Shipping',
                    controller: _shippingController,
                    validText: 'Please enter shipping information',
                  ),
                  const SizedBox(height: 15.0),
                  const Text(
                    "Choose Checker",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  DropdownButtonFormField<String>(
                    value: employees.contains(_employeeIdController.text)
                        ? _employeeIdController.text
                        : null,
                    onChanged: (value) {
                      setState(() {
                        _employeeIdController.text = value ?? '';
                      });
                    },
                    items: employees
                        .map((employee) => DropdownMenuItem<String>(
                              value: employee,
                              child: Text(employee),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Select CheckerS',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    "Due time",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  ListTile(
                    title: Text(
                      'Set due time: ${_estimatedCompletionTime != null ? _estimatedCompletionTime!.format(context) : "Not set"}',
                    ),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime:
                            _estimatedCompletionTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _estimatedCompletionTime = pickedTime;
                        });
                        // Schedule the notification
                        await AlarmNotificationService
                            .scheduleAlarmNotification(pickedTime);

                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Alarm set for ${pickedTime.format(context)}')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    "Whalf Image",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0),
                  ListTile(
                    title: _image == null
                        ? const Text('Select Image')
                        : Image.file(_image!),
                    onTap: () async {
                      await getImage();
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Add CheckboxListTile for "Stamp Signature"
                  CheckboxListTile(
                    title: const Text("Stamp Signature"),
                    value: _isSignatureStamped,
                    onChanged: (bool? value) {
                      setState(() {
                        _isSignatureStamped = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        saveWorkToFirebase();
                        notificationService.sendNotificationToChecker(
                            _employeeIdController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color.fromARGB(255, 4, 6, 126), // Background color
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.05,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create Work",
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ],
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
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
            ),
            backgroundColor: Colors.white,
            body: Center(
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'You do not have permission to access this page.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
          );
  }

  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Creating work..."),
            ],
          ),
        );
      },
    );
  }

  void handleSignatureStamping() {
    if (_isSignatureStamped) {
      _getSignature();
    }
  }

  Future<void> saveWorkToFirebase() async {
    try {
      showLoadingDialog(context);
      final CollectionReference workCollection =
          FirebaseFirestore.instance.collection('works');

      String workID = 'Work_${Random().nextInt(90000) + 10000}';

      String checkerName =
          _employeeIdController.text; // Get the selected checker's name

      // Upload the image to Firebase Storage
      String imageUrl = await uploadImageToFirebaseStorage(workID);

      Work work = Work(
        workID: workID,
        date: _dateController.text,
        consignee: _consigneeController.text,
        vessel: _vesselController.text,
        voy: _voyController.text,
        blNo: _blNoController.text,
        shipping: _shippingController.text,
        estimatedCompletionTime: _estimatedCompletionTime != null
            ? Duration(
                hours: _estimatedCompletionTime!.hour,
                minutes: _estimatedCompletionTime!.minute,
              )
            : null,
        employeeId: checkerName, // Set the checker's name as the employeeId
        dispatcherID: _dispatcherID ?? '',
        imageUrl: imageUrl, // Set the imageUrl in the Work model
        statuses: ['NoStatus'],
      );

      Map<String, dynamic> workData = work.toMap();
      await workCollection.doc(workID).set(workData);
      print('Work data saved to Firestore successfully! WorkID: $workID');
      Navigator.pop(context); // Close the loading dialog

      // Show success message and navigate to dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Work created successfully!"),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const Dashboard()), // Replace with your actual dashboard page widget
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error saving work data: $e');
      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to create work. Please try again."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String> uploadImageToFirebaseStorage(String workID) async {
    try {
      if (_image == null) {
        return '';
      }
      Reference storageReference =
          FirebaseStorage.instance.ref().child('work_images/$workID.jpg');
      await storageReference.putFile(_image!);
      String downloadURL = await storageReference.getDownloadURL();
      print('Image uploaded to Firebase Storage. Download URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
      return '';
    }
  }
}
