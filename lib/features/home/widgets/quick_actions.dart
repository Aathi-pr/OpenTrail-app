import 'package:flutter/material.dart';

import 'package:open_trail/widgets/opentrail_button.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.isCreating,
    required this.isJoining,
    required this.onCreate,
    required this.onJoin,
  });

  final bool isCreating;
  final bool isJoining;

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OpentrailButton(
          number: "01",
          title: isCreating ? "CREATING..." : "CREATE GROUP",
          subtitle: "Start a new ride and invite others.",
          onTap: isCreating ? null : onCreate,
        ),

        const SizedBox(height: 16),

        OpentrailButton(
          number: "02",
          title: isJoining ? "JOINING..." : "JOIN GROUP",
          subtitle: "Enter an invitation code to join.",
          onTap: isJoining ? null : onJoin,
        ),
      ],
    );
  }
}
