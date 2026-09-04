import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_trail/models/waypoint_model.dart';

class WaypointInfoSheet extends StatelessWidget {
  const WaypointInfoSheet({
    super.key,
    required this.waypoint,
    required this.isLeader,
    this.onEdit,
    this.onDelete,
    this.onToggleCompleted,
  });

  final WaypointModel waypoint;
  final bool isLeader;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF09090B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Header Block
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: waypoint.categoryColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(1),
                              border: Border.all(
                                color: waypoint.categoryColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                waypoint.categoryIcon,
                                color: waypoint.categoryColor,
                                size: 20,
                              ),
                            ),
                          ),
                          if (waypoint.completed)
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF09090B),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.check_mark,
                                color: Colors.black,
                                size: 9,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              waypoint.categoryLabel.toUpperCase(),
                              style: TextStyle(
                                color: waypoint.categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              waypoint.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                            ),

                            if (waypoint.locationName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                waypoint.locationName,
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: waypoint.completed
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: waypoint.completed
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          waypoint.completed
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: waypoint.completed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD4D4D8),
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          waypoint.completed ? "COMPLETED" : "PLANNED",
                          style: TextStyle(
                            color: waypoint.completed
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (waypoint.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        waypoint.description,
                        style: const TextStyle(
                          color: Color(0xFFE4E4E7),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Clear Metadata Grid
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha :0.03),
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          CupertinoIcons.clock,
                          "STOP DURATION",
                          "${waypoint.stopMinutes} min",
                        ),
                        _divider(),
                        _infoTile(
                          CupertinoIcons.location,
                          "COORDINATES",
                          "${waypoint.latitude.toStringAsFixed(5)}, ${waypoint.longitude.toStringAsFixed(5)}",
                        ),
                        _divider(),
                        _infoTile(
                          CupertinoIcons.person,
                          "CREATED BY",
                          waypoint.creatorName,
                        ),
                        _divider(),
                        _infoTile(
                          CupertinoIcons.calendar,
                          "CREATED ON",
                          _formatDate(waypoint.createdAt),
                        ),
                      ],
                    ),
                  ),

                  if (isLeader) ...[
                    const SizedBox(height: 20),

                    // Primary Action (Solid White CRED Button)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        onPressed:
                            onToggleCompleted ??
                            () {
                              Navigator.pop(context);
                            },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              waypoint.completed
                                  ? CupertinoIcons.arrow_counterclockwise
                                  : CupertinoIcons.checkmark_alt_circle_fill,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              waypoint.completed
                                  ? "MARK AS PLANNED"
                                  : "MARK COMPLETED",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Secondary Action Row
                    Row(
                      children: [
                        Expanded(
                          child: _outlineButton(
                            icon: CupertinoIcons.pencil,
                            label: "EDIT",
                            color: Colors.white,
                            onTap:
                                onEdit ??
                                () {
                                  Navigator.pop(context);
                                },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _outlineButton(
                            icon: CupertinoIcons.trash,
                            label: "DELETE",
                            color: const Color(0xFFEF4444),
                            onTap:
                                onDelete ??
                                () {
                                  Navigator.pop(context);
                                },
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: const Color(0xFFA1A1AA)),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFA1A1AA),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha :0.06),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.25), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';

    return "${date.day} ${months[date.month]} ${date.year} • $hour:$minute $ampm";
  }
}
