import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:namyong_demo/screen/Dashboard.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  XFile? _profileImage;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.getToken().then((fcmToken) {
      print('FCM Token: $fcmToken');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _profileImage != null
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage: FileImage(File(_profileImage!.path)),
                  )
                : CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person),
                  ),
            SizedBox(height: 8),
            TextButton(
              onPressed: _pickProfilePicture,
              child: Text('Select Profile Picture'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _registerWithEmailAndPassword,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerWithEmailAndPassword() async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // After registering, navigate to FillInfoPage to complete profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FillInfoPage(
            user: userCredential.user,
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            profileImage: _profileImage,
          ),
        ),
      );
    } catch (e) {
      print('Failed to register: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register. Please try again.'),
        ),
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _profileImage = image;
    });
  }
}

class FillInfoPage extends StatefulWidget {
  final User? user;
  final String email;
  final String password;
  final XFile? profileImage;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  FillInfoPage({
    required this.user,
    required this.email,
    required this.password,
    required this.profileImage,
  });

  @override
  _FillInfoPageState createState() => _FillInfoPageState();
}


class _FillInfoPageState extends State<FillInfoPage> {
  final TextEditingController _employeeIDController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String _selectedRole = '';
  XFile? _signatureImage;

  // Function to upload an image to Firebase Storage and return its download URL
  Future<String?> _uploadImageToStorage(XFile? image, String folderName) async {
    if (image == null) return null;

    try {
      final fileName = '${widget.user?.uid}_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('$folderName/$fileName');
      final uploadTask = ref.putFile(File(image.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _saveUserInfo(String fcmToken) async {
    try {
      // Upload the profile and signature images to Firebase Storage
      final profileImageUrl = await _uploadImageToStorage(widget.profileImage, 'profile_images');
      final signatureImageUrl = await _uploadImageToStorage(_signatureImage, 'signature_images');

      if (widget.user != null) {
        await FirebaseFirestore.instance.collection('Employee').doc(widget.user!.uid).set({
          'Email': widget.email,
          'EmployeeID': _employeeIDController.text,
          'Firstname': _firstNameController.text,
          'Lastname': _lastNameController.text,
          'Role': _selectedRole,
          'Password': widget.password,
          'FCMToken': fcmToken,
          'ProfileImageURL': profileImageUrl,
          'SignatureImageURL': signatureImageUrl,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      }
    } catch (e) {
      print('Error saving user info: $e');
    }
  }

  Future<void> _pickSignatureImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _signatureImage = image;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fill Information'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _employeeIDController,
              decoration: InputDecoration(labelText: 'Employee ID'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedRole = 'Dispatcher';
                });
              },
              child: Text('Dispatcher'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  return _selectedRole == 'Dispatcher' ? Colors.green : Colors.blue;
                }),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedRole = 'Checker';
                });
              },
              child: Text('Checker'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  return _selectedRole == 'Checker' ? Colors.green : Colors.blue;
                }),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedRole = 'Gate out';
                });
              },
              child: Text('Gate out'),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  return _selectedRole == 'Gate out' ? Colors.green : Colors.blue;
                }),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickSignatureImage,
              child: Text('Select Signature Image'),
            ),
            SizedBox(height: 16.0),
            _signatureImage != null
                ? Image.file(
                    File(_signatureImage!.path),
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover, 
                  )
                : SizedBox(height: 100, width: 100, child: Center(child: Text('No signature selected'))),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                widget._firebaseMessaging.getToken().then((fcmToken) {
                  _saveUserInfo(fcmToken ?? '');
                });
              },
              child: Text('Save Information'),
            ),
          ],
        ),
      ),
    );
  }
}
