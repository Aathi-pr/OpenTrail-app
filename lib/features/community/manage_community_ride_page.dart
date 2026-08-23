import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_trail/features/maps/map_page.dart';

import 'package:open_trail/models/community_ride.dart';
import 'package:open_trail/services/community_ride_service.dart';

class ManageCommunityRidePage extends StatefulWidget {
  final CommunityRide ride;

  const ManageCommunityRidePage({super.key, required this.ride});

  @override
  State<ManageCommunityRidePage> createState() =>
      _ManageCommunityRidePageState();
}

class _ManageCommunityRidePageState extends State<ManageCommunityRidePage> {
  final CommunityRideService _rideService = CommunityRideService();

  bool _isProcessing = false;

  User? get _currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  String? get _currentUid {
    return _currentUser?.uid;
  }

  bool get _isLeader {
    return _currentUid == widget.ride.leaderUid;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLeader) {
      return const _NotLeaderPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: StreamBuilder<CommunityRide?>(
          stream: _watchRide(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _LoadingState();
            }

            final ride = snapshot.data;

            if (ride == null) {
              return const _RideUnavailableState();
            }

            return _buildPage(ride);
          },
        ),
      ),
    );
  }

  Stream<CommunityRide?> _watchRide() {
    return _rideService.watchRide(widget.ride.documentId);
  }

  Widget _buildPage(CommunityRide ride) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
      children: [
        _buildHeader(),
        const SizedBox(height: 28),
        _buildRideIdentity(ride),
        const SizedBox(height: 24),
        _buildStats(ride),
        const SizedBox(height: 32),
        const _SectionMarker(number: '01', title: 'JOIN REQUESTS'),
        const SizedBox(height: 14),
        _buildJoinRequests(ride),
        const SizedBox(height: 32),
        const _SectionMarker(number: '02', title: 'RIDERS'),
        const SizedBox(height: 14),
        _buildMembers(ride),
        const SizedBox(height: 36),
        _buildStartButton(ride),
        const SizedBox(height: 12),
        _buildCancelButton(ride),
      ],
    );
  }

  Widget _buildHeader() {
    final user = _currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName;

    return Row(
      children: [
        _SquareButton(
          icon: CupertinoIcons.back,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'EXPEDITION CONTROL',
            style: TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
        ),
        _FrostedContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      CupertinoIcons.person_fill,
                      size: 11,
                      color: Color(0xFF00E676),
                    ),
                  ),
                )
              else
                const Icon(
                  CupertinoIcons.person_fill,
                  size: 11,
                  color: Color(0xFF00E676),
                ),
              const SizedBox(width: 6),
              Text(
                displayName != null && displayName.isNotEmpty
                    ? displayName.toUpperCase()
                    : 'LEADER',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideIdentity(CommunityRide ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ride.rideId.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ride.title,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ride.destination,
          style: const TextStyle(
            color: Color(0xFF8B8B8B),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1F1F1F)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    size: 13,
                    color: Color(0xFF777777),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MEETING POINT  •  ${ride.meetingPoint}',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 13,
                    color: Color(0xFF777777),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(ride.departureTime),
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(CommunityRide ride) {
    return _FrostedContainer(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(label: 'RIDERS', value: '${ride.members.length}'),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatCell(label: 'CAPACITY', value: '${ride.maxMembers}'),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatCell(
              label: 'REQUESTS',
              value: '${ride.joinRequests.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequests(CommunityRide ride) {
    if (ride.joinRequests.isEmpty) {
      return const _EmptySection(
        icon: CupertinoIcons.person_crop_circle_badge_checkmark,
        title: 'NO PENDING REQUESTS',
        subtitle: 'New rider requests will appear here.',
      );
    }

    return Column(
      children: ride.joinRequests.map((uid) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _JoinRequestTile(
            uid: uid,
            isProcessing: _isProcessing,
            onAccept: () => _acceptRequest(ride, uid),
            onReject: () => _rejectRequest(ride, uid),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMembers(CommunityRide ride) {
    final currentUser = _currentUser;

    return Column(
      children: ride.members.asMap().entries.map((entry) {
        final index = entry.key;
        final uid = entry.value;
        final isLeader = uid == ride.leaderUid;

        final photoUrl = isLeader ? currentUser?.photoURL : null;
        final displayName = isLeader ? currentUser?.displayName : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _MemberTile(
            index: index + 1,
            uid: uid,
            isLeader: isLeader,
            photoUrl: photoUrl,
            displayName: displayName,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton(CommunityRide ride) {
    final canStart = ride.status == 'published' && ride.members.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: canStart && !_isProcessing ? () => _startRide(ride) : null,
        style: TextButton.styleFrom(
          backgroundColor: canStart
              ? const Color(0xFFF4F4F2)
              : const Color(0xFF141414),
          foregroundColor: canStart
              ? const Color(0xFF080808)
              : const Color(0xFF555555),
          disabledBackgroundColor: const Color(0xFF141414),
          disabledForegroundColor: const Color(0xFF555555),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: canStart
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF222222)),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF080808),
                ),
              )
            : Text(
                ride.status == 'active'
                    ? 'EXPEDITION ACTIVE'
                    : 'START EXPEDITION',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelButton(CommunityRide ride) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: TextButton(
        onPressed:
            _isProcessing ||
                ride.status == 'cancelled' ||
                ride.status == 'active'
            ? null
            : () => _confirmCancel(ride),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF777777),
          disabledForegroundColor: const Color(0xFF444444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF222222)),
          ),
        ),
        child: const Text(
          'CANCEL EXPEDITION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(CommunityRide ride, String uid) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _rideService.acceptJoinRequest(
        documentId: ride.documentId,
        userId: uid,
      );

      if (!mounted) return;
      _showMessage('Rider accepted into the expedition.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectRequest(CommunityRide ride, String uid) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _rideService.rejectJoinRequest(
        documentId: ride.documentId,
        userId: uid,
      );

      if (!mounted) return;
      _showMessage('Join request rejected.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _startRide(CommunityRide ride) async {
    if (_isProcessing) return;

    final confirmed = await _showStartConfirmation();
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final operationalRideId = await _rideService.startRide(ride.documentId);

      if (!mounted) return;
      _showMessage('Expedition started.');

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MapPage(rideDocumentId: operationalRideId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmCancel(CommunityRide ride) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Cancel Expedition?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'All riders will no longer be able to join this expedition.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Ride'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await _rideService.cancelRide(ride.documentId);

      if (!mounted) return;
      _showMessage('Expedition cancelled.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showStartConfirmation() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Start Expedition?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'The expedition will become active for all joined riders.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Yet'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF282828)),
          ),
        ),
      );
  }

  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }

  String _formatDate(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '  •  $hour:$minute $period';
  }
}

class _JoinRequestTile extends StatelessWidget {
  final String uid;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _JoinRequestTile({
    required this.uid,
    required this.isProcessing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _FrostedContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(uid: uid),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RIDER REQUEST',
                      style: TextStyle(
                        color: Color(0xFFF4F4F2),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      uid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallActionButton(
                  label: 'REJECT',
                  onTap: isProcessing ? null : onReject,
                  filled: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallActionButton(
                  label: 'ACCEPT',
                  onTap: isProcessing ? null : onAccept,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final int index;
  final String uid;
  final bool isLeader;
  final String? photoUrl;
  final String? displayName;

  const _MemberTile({
    required this.index,
    required this.uid,
    required this.isLeader,
    this.photoUrl,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = isLeader
        ? (displayName != null && displayName!.isNotEmpty
              ? displayName!.toUpperCase()
              : 'YOU (LEADER)')
        : 'RIDER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLeader ? const Color(0xFF2A2A2A) : const Color(0xFF1B1B1B),
        ),
      ),
      child: Row(
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          _Avatar(uid: uid, photoUrl: photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                if (isLeader && displayName != null)
                  Text(
                    uid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 8,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          if (isLeader)
            const Text(
              'LEADER',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String uid;
  final String? photoUrl;

  const _Avatar({required this.uid, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final letter = uid.isEmpty ? '?' : uid[0].toUpperCase();

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(letter),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.2,
                      color: Color(0xFF666666),
                    ),
                  ),
                );
              },
            )
          : _buildFallback(letter),
    );
  }

  Widget _buildFallback(String letter) {
    return Text(
      letter,
      style: TextStyle(
        color: const Color(0xFFCCCCCC),
        fontSize: 32 * 0.35,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _SmallActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: filled
              ? const Color(0xFFF4F4F2)
              : const Color(0xFF141414),
          foregroundColor: filled
              ? const Color(0xFF080808)
              : const Color(0xFF888888),
          disabledBackgroundColor: const Color(0xFF141414),
          disabledForegroundColor: const Color(0xFF444444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF262626)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }
}

class _SectionMarker extends StatelessWidget {
  final String number;
  final String title;

  const _SectionMarker({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '[ $number ]',
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: const Color(0xFF1A1A1A))),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptySection({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF444444), size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FrostedContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _FrostedContainer({
    required this.child,
    this.borderRadius = 12,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF222222), width: 0.8),
      ),
      child: child,
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: const Color(0xFFF4F4F2), size: 16),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: Color(0xFFF4F4F2),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
        ),
      ),
    );
  }
}

class _RideUnavailableState extends StatelessWidget {
  const _RideUnavailableState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'EXPEDITION NO LONGER AVAILABLE',
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: const Color(0xFF222222));
  }
}

class _NotLeaderPage extends StatelessWidget {
  const _NotLeaderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        foregroundColor: const Color(0xFFF4F4F2),
        elevation: 0,
        title: const Text(
          'EXPEDITION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.lock,
                color: Color(0xFF444444),
                size: 36,
              ),
              const SizedBox(height: 20),
              const Text(
                'ACCESS RESTRICTED',
                style: TextStyle(
                  color: Color(0xFFF4F4F2),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Only the ride leader can manage this expedition.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F4F2),
                    foregroundColor: const Color(0xFF080808),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'GO BACK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
