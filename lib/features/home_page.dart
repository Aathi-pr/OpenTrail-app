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
  bool _isJoiningRide = false;

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

  Future<void> _showJoinRideDialog() async {
    final controller = TextEditingController();

    final rideId = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Join",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        const bg = Color(0xFF0A0A0A);
        const fg = Color(0xFFF5F5F2);
        const secondary = Color(0xFF8B8B8B);
        const border = Color(0xFF242424);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "JOIN GROUP",
                          style: TextStyle(
                            color: fg,
                            fontSize: 18,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: fg),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Container(width: 48, height: 1, color: fg),

                  const SizedBox(height: 32),

                  const Text(
                    "Enter your\ninvitation code.",
                    style: TextStyle(
                      color: fg,
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Use the code shared by the ride owner.",
                    style: TextStyle(
                      color: secondary,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 56),

                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: fg,
                      fontSize: 30,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                    ),
                    decoration: const InputDecoration(
                      hintText: "OT-XXXXXX",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        letterSpacing: 6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: fg),
                      ),
                    ),
                    onSubmitted: (value) =>
                        Navigator.pop(context, value.trim()),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: fg,
                        side: const BorderSide(color: border),
                        backgroundColor: const Color(0xFF111111),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        "JOIN GROUP",
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );

    if (rideId == null || rideId.trim().isEmpty) return;

    await _joinRide(rideId.trim());
  }

  Future<void> _joinRide(String rideId) async {
    if (_isJoiningRide) return;

    setState(() {
      _isJoiningRide = true;
    });

    try {
      final ride = await _rideService.joinRide(rideId);

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
      ).showSnackBar(SnackBar(content: Text('Failed to join ride: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningRide = false;
        });
      }
    }
  }

@override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);
    const fg = Color(0xFFF4F4F2);
    const secondary = Color(0xFF8B8B8B);
    const border = Color(0xFF242424);
    const card = Color(0xFF111111);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "OPEN TRAIL",
                      style: TextStyle(
                        color: fg,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                      ),
                    ),
                  ),

                  IconButton(
                    splashRadius: 20,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined, color: fg),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              Container(width: 48, height: 1, color: fg),

              const SizedBox(height: 28),

              const Text(
                "Begin a\nshared journey.",
                style: TextStyle(
                  color: fg,
                  fontSize: 44,
                  height: 1.05,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Create a group and explore\n"
                "together in real time.",
                style: TextStyle(color: secondary, fontSize: 17, height: 1.5),
              ),

              const SizedBox(height: 36),

              Container(width: 48, height: 1, color: fg),

              const SizedBox(height: 88),

              OpentrailButton(
                number: "01",
                title: _isCreatingRide ? "CREATING..." : "CREATE GROUP",
                subtitle: "Start a new ride and invite others.",
                onTap: _isCreatingRide ? null : _createRide,
              ),

              const SizedBox(height: 18),

              OpentrailButton(
                number: "02",
                title: _isJoiningRide ? "JOINING..." : "JOIN WITH CODE",
                subtitle: "Enter an invitation code to join.",
                onTap: _isJoiningRide ? null : _showJoinRideDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
