class NavigationStep {
  final String instruction;
  final double distance;
  final double duration;
  final int type;
  final int waypointIndex;

  const NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.type,
    required this.waypointIndex,
  });
}
