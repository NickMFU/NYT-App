import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ScanBarcodePage extends StatefulWidget {
  @override
  _ScanBarcodePageState createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  List<String> _scannedBarcodes = [];
  CollectionReference _worksCollection =
      FirebaseFirestore.instance.collection('works');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Barcode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                _scanBarcode();
              },
              child: Text('Scan Barcode'),
            ),
            SizedBox(height: 20),
            Text(
              'Scanned Barcodes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _scannedBarcodes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_scannedBarcodes[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteBarcode(index);
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _saveScannedBarcodes();
              },
              child: Text('Save Barcodes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeResult = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // color of the toolbar
        'Cancel', // text for the cancel button
        true, // show flash icon
        ScanMode.BARCODE, // specify the scan mode
      );

      if (!mounted) return;

      setState(() {
        _scannedBarcodes.add(barcodeResult);
      });
    } catch (e) {
      // Handle error
      print('Error: $e');
    }
  }

  void _deleteBarcode(int index) {
    setState(() {
      _scannedBarcodes.removeAt(index);
    });
  }

  Future<void> _saveScannedBarcodes() async {
    try {
      String workID = 'YOUR_WORK_ID'; // Replace with the actual work ID

      // Create a reference to the 'items' subcollection of the specified work
      CollectionReference itemsCollection =
          _worksCollection.doc(workID).collection('items');

      for (String barcode in _scannedBarcodes) {
        String documentId = 'Item_${Random().nextInt(90000) + 10000}';

        // Add each scanned barcode to the 'items' subcollection
        await itemsCollection.doc(documentId).set({
          'barcode': barcode,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Clear the scanned barcodes list after saving to the database
      setState(() {
        _scannedBarcodes.clear();
      });

      print('Scanned barcodes saved to Firestore in the "items" subcollection.');
    } catch (e) {
      print('Error saving scanned barcodes: $e');
    }
  }
}
