import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {

  bool loading = false;

  //  GPS permission + location
  Future<Position> getLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permission denied forever");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  //  calculate distance
  double calculateDistance(lat1, lon1, lat2, lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  //  find nearest ambulance
  Future<DocumentSnapshot?> getNearestAmbulance(Position userPos) async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection("ambulances").get();
    print("Ambulances found: ${snapshot.docs.length}");
    print(snapshot.docs.length);  
    DocumentSnapshot? nearest;
    double minDistance = double.infinity;

    for (var doc in snapshot.docs) {
      double ambLat = doc['lat'];
      double ambLng = doc['lng'];

      double distance = calculateDistance(
        userPos.latitude,
        userPos.longitude,
        ambLat,
        ambLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = doc;
      }
    }

    return nearest;
  }

  //  SEND SOS
  Future<void> sendSOS() async {
    setState(() => loading = true);

    try {
      // 1. get GPS
      Position pos = await getLocation();

      // 2. find nearest ambulance
      DocumentSnapshot? ambulance =
          await getNearestAmbulance(pos);

      // 3. send request to Firebase
      await FirebaseFirestore.instance.collection("requests").add({
        "status": "pending",
        "lat": pos.latitude,
        "lng": pos.longitude,
        "ambulanceId": ambulance?.id ?? "none",
        "time": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" SOS Sent Successfully")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text("Emergency SOS"),
        backgroundColor: Colors.red,
      ),

      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20),
                ),
                onPressed: sendSOS,
                child: const Text(
                  " طلب النجدة",
                  style: TextStyle(fontSize: 20 , color: Colors.white),
                ),
              ),
      ),
    );
  }
}