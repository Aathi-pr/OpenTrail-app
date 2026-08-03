import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/models/waypoint_model.dart';
import 'package:open_trail/services/waypoint_service.dart';

class AddWaypointSheet extends StatefulWidget {
  const AddWaypointSheet({
    super.key,
    required this.rideId,
    required this.location,
    required this.locationName,
    this.waypoint,
  });

  final String rideId;
  final LatLng location;
  final String locationName;
  final WaypointModel? waypoint;

  @override
  State<AddWaypointSheet> createState() => _AddWaypointSheetState();
}

class _AddWaypointSheetState extends State<AddWaypointSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final WaypointService _waypointService = WaypointService();

  WaypointCategory _selectedCategory = WaypointCategory.food;
  int _stopMinutes = 20;

  bool _saving = false;

  bool get _isEditing => widget.waypoint != null;

  @override
  void initState() {
    super.initState();

    final waypoint = widget.waypoint;
    if (waypoint == null) return;

    _titleController.text = waypoint.title;
    _descriptionController.text = waypoint.description;
    _selectedCategory = waypoint.category;
    _stopMinutes = waypoint.stopMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          
          content: Text("Waypoint title is required."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1E1E1E),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final waypoint = WaypointModel(
        id: widget.waypoint?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        locationName: widget.locationName,
        order: widget.waypoint?.order ?? 0,
        category: _selectedCategory,
        stopMinutes: _stopMinutes,
        completed: widget.waypoint?.completed ?? false,
        creatorId:
            widget.waypoint?.creatorId ??
            FirebaseAuth.instance.currentUser!.uid,
        creatorName: widget.waypoint?.creatorName ?? '',
        createdAt: widget.waypoint?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _waypointService.updateWaypoint(
          rideId: widget.rideId,
          waypoint: waypoint,
        );
      } else {
        await _waypointService.addWaypoint(
          rideId: widget.rideId,
          waypoint: waypoint,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E1E1E),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildCategoryTile(WaypointCategory category) {
    final selected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
            color: selected ? Colors.white : const Color(0xFF222222),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 14,
              color: selected ? Colors.black : const Color(0xFF888888),
            ),
            const SizedBox(width: 8),
            Text(
              category.label.toUpperCase(),
              style: TextStyle(
                color: selected ? Colors.black : const Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black, // CRED-style pure OLED black canvas
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CRED Handle pill
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? "Edit waypoint" : "Add waypoint",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(color: const Color(0xFF262626)),
                      ),
                      child: Text(
                        "WAYPOINT",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Location Display (CRED Card Style)
                _buildSectionHeader("LOCATION DETAILS"),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0C0C),
                    borderRadius: BorderRadius.circular(1),
                    border: Border.all(color: const Color(0xFF1F1F1F)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(1),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.locationName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}",
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Title Input
                _buildSectionHeader("TITLE"),
                const SizedBox(height: 8),

                _buildCredTextField(
                  controller: _titleController,
                  hint: "e.g. Breakfast stop",
                ),

                const SizedBox(height: 20),

                // Description Input
                _buildSectionHeader("DESCRIPTION"),
                const SizedBox(height: 8),

                _buildCredTextField(
                  controller: _descriptionController,
                  hint: "e.g. Meet back at the bikes after breakfast",
                ),

                const SizedBox(height: 24),

                // Category Selector
                _buildSectionHeader("CATEGORY"),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WaypointCategory.values
                      .map(_buildCategoryTile)
                      .toList(),
                ),

                const SizedBox(height: 28),

                // Stop Duration Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader("STOP DURATION"),
                    Text(
                      "$_stopMinutes MINS",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF222222),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: GlassSlider(
                    trackHeight: 5,
                    inactiveColor: Colors.white30,
                    quality: GlassQuality.premium,
                    useOwnLayer: true,
                    activeColor: Colors.blueAccent,
                    value: _stopMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (value) {
                      setState(() {
                        _stopMinutes = value.round();
                      });
                    },
                  ),
                ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _saving
                                ? (_isEditing ? "SAVING..." : "CREATING...")
                                : (_isEditing
                                      ? "SAVE WAYPOINT"
                                      : "ADD WAYPOINT"),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isEditing
                                ? CupertinoIcons.check_mark
                                : CupertinoIcons.arrow_right,
                            color: Colors.black,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF555555),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCredTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: const Color(0xFF1F1F1F)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF444444),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

extension _WaypointCategoryPresentation on WaypointCategory {
  String get label {
    switch (this) {
      case WaypointCategory.food:
        return 'Food';
      case WaypointCategory.fuel:
        return 'Fuel';
      case WaypointCategory.hotel:
        return 'Hotel';
      case WaypointCategory.viewpoint:
        return 'Viewpoint';
      case WaypointCategory.rest:
        return 'Rest';
      case WaypointCategory.checkpoint:
        return 'Checkpoint';
      case WaypointCategory.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case WaypointCategory.food:
        return CupertinoIcons.square_grid_2x2_fill;
      case WaypointCategory.fuel:
        return CupertinoIcons.drop_fill;
      case WaypointCategory.hotel:
        return CupertinoIcons.house_fill;
      case WaypointCategory.viewpoint:
        return CupertinoIcons.camera_fill;
      case WaypointCategory.rest:
        return CupertinoIcons.bed_double_fill;
      case WaypointCategory.checkpoint:
        return CupertinoIcons.flag_fill;
      case WaypointCategory.custom:
        return CupertinoIcons.location_solid;
    }
  }
}
