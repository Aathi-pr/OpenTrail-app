import 'package:flutter/material.dart';
import 'package:open_trail/features/maps/map_page.dart';
import 'package:open_trail/features/settings/settings_page.dart';
import 'package:open_trail/services/ride_service.dart';
import 'package:open_trail/widgets/opentrail_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RideService _rideService = RideService();
  bool _isCreatingRide = false;

  Future<void> _createRide() async {
    if (_isCreatingRide) return;

    setState(() {
      _isCreatingRide = true;
    });

    try {
      final ride = await _rideService.createRide();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapPage(rideDocumentId: ride.documentId, initialRide: ride),
        ),
      );
    } on RideException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create ride: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRide = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "O P E N   T R A I L",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: Icon(Icons.settings),
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 500),
            OpentrailButton(
              icon: Icons.add,
              text: _isCreatingRide ? "Creating..." : "Create Group",
              onPressed: _isCreatingRide ? null : _createRide,
            ),
            SizedBox(height: 20),
            OpentrailButton(
              icon: Icons.join_full_outlined,
              text: "Join Group",
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
