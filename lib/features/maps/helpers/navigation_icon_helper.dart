import 'package:flutter/material.dart';

IconData navigationIconForType(int type) {
  switch (type) {
    case 0: // Left
      return Icons.turn_left;

    case 1: // Right
      return Icons.turn_right;

    case 2: // Sharp left
      return Icons.turn_sharp_left;

    case 3: // Sharp right
      return Icons.turn_sharp_right;

    case 4: // Slight left
      return Icons.turn_slight_left;

    case 5: // Slight right
      return Icons.turn_slight_right;

    case 6: // Straight
      return Icons.straight;

    case 7: // Enter roundabout
      return Icons.roundabout_left;

    case 8: // Exit roundabout
      return Icons.roundabout_right;

    case 9: // U-turn
      return Icons.u_turn_left;

    case 10: // Destination
      return Icons.flag;

    case 11: // Depart
      return Icons.trip_origin;

    case 12: // Keep left
      return Icons.fork_left;

    case 13: // Keep right
      return Icons.fork_right;

    default:
      return Icons.navigation;
  }
}
