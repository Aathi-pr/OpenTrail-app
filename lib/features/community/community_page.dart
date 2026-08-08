import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_trail/features/weather/dynamic_weather_background.dart';
import 'package:open_trail/features/weather/weather_condition.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    "ALL TRAILS",
    "ADVENTURE",
    "TOURING",
    "WEEKEND",
    "NEARBY",
  ];

  final List<Map<String, dynamic>> _expeditions = [
    {
      "id": "01",
      "title": "Munnar Sunrise Pass",
      "location": "MUNNAR • HIGH RANGE",
      "distance": "120 KM",
      "riders": "42 PILOTS",
      "departure": "SAT 05:30 AM",
      "weather": {
        "temp": "16°C",
        "conditionText": "HEAVY MIST & FOG",
        "conditionEnum": WeatherCondition.foggy,
        "icon": CupertinoIcons.cloud_fog,
        "visibility": "1.2 KM",
        "wind": "14 KM/H NW",
        "impact": "WET TAR • LOW VISIBILITY",
      },
    },
    {
      "id": "02",
      "title": "Vagamon Misty Ridge",
      "location": "VAGAMON • IDUKKI",
      "distance": "85 KM",
      "riders": "18 PILOTS",
      "departure": "TOMORROW 06:00 AM",
      "weather": {
        "temp": "19°C",
        "conditionText": "HEAVY RAIN & DRIZZLE",
        "conditionEnum": WeatherCondition.heavyRain,
        "icon": CupertinoIcons.cloud_rain,
        "visibility": "3.5 KM",
        "wind": "18 KM/H W",
        "impact": "SLIPPERY CURVES",
      },
    },
    {
      "id": "03",
      "title": "Wayanad Hairpin Run",
      "location": "WAYANAD • GHAT PASS",
      "distance": "210 KM",
      "riders": "31 PILOTS",
      "departure": "AUG 12 • 05:00 AM",
      "weather": {
        "temp": "22°C",
        "conditionText": "SEVERE THUNDERSTORM",
        "conditionEnum": WeatherCondition.thunderstorm,
        "icon": CupertinoIcons.cloud_bolt,
        "visibility": "2.0 KM",
        "wind": "32 KM/H SW",
        "impact": "FLASH LIGHTNING",
      },
    },
    {
      "id": "04",
      "title": "Athirappilly River Cruise",
      "location": "ATHIRAPPILLY • FOREST",
      "distance": "140 KM",
      "riders": "25 PILOTS",
      "departure": "AUG 15 • 06:30 AM",
      "weather": {
        "temp": "25°C",
        "conditionText": "CLEAR NIGHT SKY",
        "conditionEnum": WeatherCondition.clearDark,
        "icon": CupertinoIcons.moon_stars,
        "visibility": "10.0 KM",
        "wind": "8 KM/H WNW",
        "impact": "OPTIMAL TACK",
      },
    },
    {
      "id": "05",
      "title": "Ponmudi Peak Climb",
      "location": "PONMUDI • TRIVANDRUM",
      "distance": "95 KM",
      "riders": "14 PILOTS",
      "departure": "AUG 20 • 05:30 AM",
      "weather": {
        "temp": "18°C",
        "conditionText": "STRONG CROSSWINDS",
        "conditionEnum": WeatherCondition.windy,
        "icon": CupertinoIcons.wind,
        "visibility": "5.0 KM",
        "wind": "24 KM/H S",
        "impact": "HIGH SIDE-GUSTS",
      },
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCreateRidePressed() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('SCHEDULE UPCOMING RIDE'),
        message: const Text(
          'Dispatch a new trail run, weekend cruise, or group expedition.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Public Trail Ride'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Private Group Dispatch'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          itemCount: 7 + _expeditions.length - 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "CLUB // EXPEDITIONS",
                    style: TextStyle(
                      color: Color(0xFF8B8B8B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.0,
                    ),
                  ),
                  _FrostedContainer(
                    borderRadius: 20,
                    onTap: _onCreateRidePressed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          color: Color(0xFFF4F4F2),
                          size: 13,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "CREATE RIDE",
                          style: TextStyle(
                            color: Color(0xFFF4F4F2),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (index == 1) {
              return const Padding(
                padding: EdgeInsets.only(top: 20, bottom: 24),
                child: Text(
                  "EXPLORE\nPUBLIC TRAILS.",
                  style: TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 32,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
              );
            }

            if (index == 2) {
              return _FrostedSearchBar(controller: _searchController);
            }

            if (index == 3) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, filterIdx) {
                      return _FilterSegment(
                        label: _filters[filterIdx],
                        isSelected: _selectedFilterIndex == filterIdx,
                        onTap: () => setState(() => _selectedFilterIndex = filterIdx),
                      );
                    },
                  ),
                ),
              );
            }

            if (index == 4) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: _SectionMarker(number: "01", title: "FEATURED EXPEDITION"),
              );
            }

            if (index == 5) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: _WeatherBackdropCard(
                  data: _expeditions[0],
                  isFeatured: true,
                ),
              );
            }

            if (index == 6) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: _SectionMarker(number: "02", title: "UPCOMING DISPATCHES"),
              );
            }

            final expeditionData = _expeditions[index - 6];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _WeatherBackdropCard(
                data: expeditionData,
                isFeatured: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WeatherBackdropCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isFeatured;

  const _WeatherBackdropCard({required this.data, required this.isFeatured});

  @override
  Widget build(BuildContext context) {
    final weather = data['weather'];
    final WeatherCondition condition =
        weather['conditionEnum'] ?? WeatherCondition.clearDark;
    final String conditionText = weather['conditionText'] ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured ? const Color(0xFF333333) : const Color(0xFF222222),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // RepaintBoundary prevents background canvas repaints from triggering recalculations on text/widgets above
            Positioned.fill(
              child: RepaintBoundary(
                child: DynamicWeatherBackground(condition: condition),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isFeatured
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFF8B8B8B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data['location'],
                            style: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      _FrostedContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              weather['icon'] as IconData,
                              color: const Color(0xFFF4F4F2),
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              weather['temp'],
                              style: const TextStyle(
                                color: Color(0xFFF4F4F2),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data['title'],
                    style: const TextStyle(
                      color: Color(0xFFF4F4F2),
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$conditionText  •  VISIBILITY ${weather['visibility']}",
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _FrostedContainer(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SpecCell(label: "DIST", value: data['distance']),
                        Container(width: 1, height: 22, color: Colors.white10),
                        _SpecCell(label: "GROUP", value: data['riders']),
                        Container(width: 1, height: 22, color: Colors.white10),
                        _SpecCell(label: "DEPART", value: data['departure']),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F4F2),
                        foregroundColor: const Color(0xFF080808),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "JOIN EXPEDITION",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zero-cost Frosted Glass substitute using hardware-accelerated opacities & borders
class _FrostedContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _FrostedContainer({
    required this.child,
    this.borderRadius = 12,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withOpacity(0.55),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: container,
      ),
    );
  }
}

class _FrostedSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _FrostedSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _FrostedContainer(
      borderRadius: 10,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFFF4F4F2),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            cursorColor: const Color(0xFFF4F4F2),
            decoration: const InputDecoration(
              hintText: "SEARCH ROUTES, WAYPOINTS, CLUBS...",
              hintStyle: TextStyle(
                color: Color(0xFF666666),
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: Color(0xFF8B8B8B),
                size: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecCell extends StatelessWidget {
  final String label;
  final String value;

  const _SpecCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
          "[ $number ]",
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: const Color(0xFF1F1F1F))),
      ],
    );
  }
}

class _FilterSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F4F2) : const Color(0xFF101010),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF4F4F2)
                : const Color(0xFF222222),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF080808)
                  : const Color(0xFF8B8B8B),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
