import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:open_trail/models/waypoint_model.dart';
import 'package:open_trail/services/community_ride_service.dart';
import 'package:open_trail/services/location_search_service.dart';
import 'package:open_trail/widgets/inline_search_results.dart';

class CreateCommunityRidePage extends StatefulWidget {
  const CreateCommunityRidePage({super.key});

  @override
  State<CreateCommunityRidePage> createState() =>
      _CreateCommunityRidePageState();
}

class _CreateCommunityRidePageState extends State<CreateCommunityRidePage> {
  final CommunityRideService _communityRideService = CommunityRideService();

  final LocationSearchService _locationSearchService = LocationSearchService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _meetingPointController = TextEditingController();

  final TextEditingController _destinationController = TextEditingController();

  final TextEditingController _fuelController = TextEditingController();

  final TextEditingController _tollController = TextEditingController();

  final TextEditingController _parkingController = TextEditingController();

  final TextEditingController _accommodationController =
      TextEditingController();

  final TextEditingController _otherCostController = TextEditingController();

  final TextEditingController _vehicleRequirementController =
      TextEditingController();

  final TextEditingController _instructionsController = TextEditingController();

  DateTime? _departureTime;

  DateTime? _returnTime;

  bool _isRoundTrip = false;

  String _selectedCategory = 'Adventure';

  String _selectedDifficulty = 'Moderate';

  String _selectedTerrain = 'Mixed';

  int _maxMembers = 20;

  bool _isPublic = true;

  bool _helmetRequired = true;

  bool _licenceRequired = true;

  bool _isPublishing = false;

  LatLng? _selectedMeetingPoint;

  String? _selectedMeetingPointLabel;

  LatLng? _selectedDestination;

  String? _selectedDestinationLabel;

  final List<_WaypointDraft> _waypoints = <_WaypointDraft>[];

  Timer? _meetingPointSearchDebounce;

  Timer? _destinationSearchDebounce;

  List<dynamic> _meetingPointSearchResults = <dynamic>[];

  List<dynamic> _destinationSearchResults = <dynamic>[];

  bool _isMeetingPointSearching = false;

  bool _isDestinationSearching = false;

  bool _showMeetingPointResults = false;

  bool _showDestinationResults = false;

  final List<String> _categories = <String>[
    'Adventure',
    'Touring',
    'Weekend',
    'Night Ride',
    'Offroad',
    'Custom',
  ];

  final List<String> _difficulties = <String>[
    'Easy',
    'Moderate',
    'Hard',
    'Extreme',
  ];

  final List<String> _terrains = <String>[
    'Mixed',
    'Highway',
    'Mountain',
    'Offroad',
    'Coastal',
    'Forest',
  ];

  @override
  void initState() {
    super.initState();

    _meetingPointController.addListener(_onMeetingPointTextChanged);
    _destinationController.addListener(_onDestinationTextChanged);
  }

  @override
  void dispose() {
    _meetingPointSearchDebounce?.cancel();
    _destinationSearchDebounce?.cancel();

    _titleController.dispose();
    _meetingPointController.dispose();
    _destinationController.dispose();

    _fuelController.dispose();
    _tollController.dispose();
    _parkingController.dispose();
    _accommodationController.dispose();
    _otherCostController.dispose();

    _vehicleRequirementController.dispose();
    _instructionsController.dispose();

    super.dispose();
  }

  void _onMeetingPointTextChanged() {
    final query = _meetingPointController.text.trim();

    if (_selectedMeetingPointLabel != null &&
        query != _selectedMeetingPointLabel) {
      _selectedMeetingPoint = null;
      _selectedMeetingPointLabel = null;
    }

    _meetingPointSearchDebounce?.cancel();

    if (query.isEmpty) {
      if (!mounted) return;

      setState(() {
        _meetingPointSearchResults = <dynamic>[];
        _isMeetingPointSearching = false;
        _showMeetingPointResults = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _showMeetingPointResults = true;
    });

    _meetingPointSearchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchMeetingPoint(query),
    );
  }

  Future<void> _searchMeetingPoint(String query) async {
    if (!mounted) return;

    setState(() {
      _isMeetingPointSearching = true;
    });

    try {
      final results = await _locationSearchService.searchPlaces(query);

      if (!mounted) return;

      if (_meetingPointController.text.trim() != query) {
        return;
      }

      setState(() {
        _meetingPointSearchResults = results;
        _isMeetingPointSearching = false;
        _showMeetingPointResults = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _meetingPointSearchResults = <dynamic>[];
        _isMeetingPointSearching = false;
      });
    }
  }

  void _onMeetingPointSelected(LatLng location, String locationName) {
    FocusManager.instance.primaryFocus?.unfocus();
    _meetingPointSearchDebounce?.cancel();

    setState(() {
      _selectedMeetingPoint = location;
      _selectedMeetingPointLabel = locationName;
      _meetingPointController.text = locationName;

      _meetingPointSearchResults = <dynamic>[];
      _isMeetingPointSearching = false;
      _showMeetingPointResults = false;
    });
  }

  void _onDestinationTextChanged() {
    final query = _destinationController.text.trim();

    if (_selectedDestinationLabel != null &&
        query != _selectedDestinationLabel) {
      _selectedDestination = null;
      _selectedDestinationLabel = null;
    }

    _destinationSearchDebounce?.cancel();

    if (query.isEmpty) {
      if (!mounted) return;

      setState(() {
        _destinationSearchResults = <dynamic>[];
        _isDestinationSearching = false;
        _showDestinationResults = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _showDestinationResults = true;
    });

    _destinationSearchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchDestination(query),
    );
  }

  Future<void> _searchDestination(String query) async {
    if (!mounted) return;

    setState(() {
      _isDestinationSearching = true;
    });

    try {
      final results = await _locationSearchService.searchPlaces(query);

      if (!mounted) return;

      if (_destinationController.text.trim() != query) {
        return;
      }

      setState(() {
        _destinationSearchResults = results;
        _isDestinationSearching = false;
        _showDestinationResults = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _destinationSearchResults = <dynamic>[];
        _isDestinationSearching = false;
      });
    }
  }

  void _onDestinationSelected(LatLng location, String locationName) {
    FocusManager.instance.primaryFocus?.unfocus();
    _destinationSearchDebounce?.cancel();

    setState(() {
      _selectedDestination = location;
      _selectedDestinationLabel = locationName;
      _destinationController.text = locationName;

      _destinationSearchResults = <dynamic>[];
      _isDestinationSearching = false;
      _showDestinationResults = false;
    });
  }

  Future<void> _addWaypoint() async {
    final result = await showModalBottomSheet<_WaypointDraft>(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      isScrollControlled: true,
      builder: (_) {
        return _WaypointSearchSheet(
          locationSearchService: _locationSearchService,
          order: _waypoints.length + 1,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _waypoints.add(result);
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);

      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = _waypoints[i].copyWith(order: i + 1);
      }
    });
  }

  Future<void> _pickDepartureTime() async {
    final value = await _pickDateTime(
      initialDate:
          _departureTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      _departureTime = value;

      if (_returnTime != null && !_returnTime!.isAfter(value)) {
        _returnTime = null;
      }
    });
  }

  Future<void> _pickReturnTime() async {
    if (_departureTime == null) {
      _showError('Select the departure date first.');
      return;
    }

    final value = await _pickDateTime(
      initialDate: _returnTime ?? _departureTime!.add(const Duration(days: 1)),
      firstDate: _departureTime!,
    );

    if (value == null || !mounted) {
      return;
    }

    if (!value.isAfter(_departureTime!)) {
      _showError('Return time must be after departure.');
      return;
    }

    setState(() {
      _returnTime = value;
    });
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialDate,
    required DateTime firstDate,
  }) async {
    DateTime safeInitialDate = initialDate;

    if (safeInitialDate.isBefore(firstDate)) {
      safeInitialDate = firstDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF141414),
              primary: Color(0xFFF4F4F2),
              onPrimary: Color(0xFF080808),
              onSurface: Color(0xFFF4F4F2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(safeInitialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              surface: Color(0xFF141414),
              primary: Color(0xFFF4F4F2),
              onPrimary: Color(0xFF080808),
              onSurface: Color(0xFFF4F4F2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _publishRide() async {
    if (_isPublishing) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMeetingPoint == null) {
      _showError('Please select a starting point.');
      return;
    }

    if (_selectedDestination == null) {
      _showError('Please select a destination.');
      return;
    }

    if (_departureTime == null) {
      _showError('Please select a departure date and time.');
      return;
    }

    if (_departureTime!.isBefore(DateTime.now())) {
      _showError('Departure time must be in the future.');
      return;
    }

    if (_isRoundTrip) {
      if (_returnTime == null) {
        _showError('Please select a return date and time.');
        return;
      }

      if (!_returnTime!.isAfter(_departureTime!)) {
        _showError('Return time must be after departure.');
        return;
      }
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final now = DateTime.now();

      final waypoints = _waypoints.map((waypoint) {
        return WaypointModel(
          id: waypoint.id,
          title: waypoint.title,
          description: '',
          latitude: waypoint.location.latitude,
          longitude: waypoint.location.longitude,
          locationName: waypoint.locationName,
          stopMinutes: waypoint.stopMinutes,
          order: waypoint.order,
          category: WaypointCategory.custom,
          completed: false,
          creatorId: '',
          creatorName: '',
          createdAt: now,
        );
      }).toList();

      final ride = await _communityRideService.createCommunityRide(
        title: _titleController.text.trim(),

        meetingPoint: _selectedMeetingPointLabel!,

        meetingPointLatitude: _selectedMeetingPoint!.latitude,

        meetingPointLongitude: _selectedMeetingPoint!.longitude,

        destination: _selectedDestinationLabel!,

        destinationLatitude: _selectedDestination!.latitude,

        destinationLongitude: _selectedDestination!.longitude,

        waypoints: waypoints,

        fuelCost: _money(_fuelController),

        tollCost: _money(_tollController),

        parkingCost: _money(_parkingController),

        accommodationCost: _money(_accommodationController),

        otherCost: _money(_otherCostController),

        departureTime: _departureTime!,

        returnTime: _isRoundTrip ? _returnTime : null,

        isRoundTrip: _isRoundTrip,

        category: _selectedCategory,

        difficulty: _selectedDifficulty,

        terrain: _selectedTerrain,

        maxMembers: _maxMembers,

        isPublic: _isPublic,

        helmetRequired: _helmetRequired,

        licenceRequired: _licenceRequired,

        vehicleRequirement: _vehicleRequirementController.text.trim(),

        additionalInstructions: _instructionsController.text.trim(),
        description: '',
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, ride);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  double _money(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                  children: [
                    const Text(
                      'PUBLISH\nYOUR EXPEDITION.',
                      style: TextStyle(
                        color: Color(0xFFF4F4F2),
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Define the route, schedule, cost and rider '
                      'requirements before inviting the community.',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    const _SectionLabel(number: '01', title: 'EXPEDITION'),

                    const SizedBox(height: 16),

                    _InputField(
                      controller: _titleController,
                      label: 'RIDE NAME',
                      hint: 'Munnar Sunrise Pass',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a ride name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 36),

                    const _SectionLabel(number: '02', title: 'ROUTE'),

                    const SizedBox(height: 16),

                    _buildLocationField(
                      label: 'START / MEETING POINT',
                      controller: _meetingPointController,
                      selected: _selectedMeetingPoint,
                      selectedLabel: _selectedMeetingPointLabel,
                      results: _meetingPointSearchResults,
                      loading: _isMeetingPointSearching,
                      showResults: _showMeetingPointResults,
                      onSelected: _onMeetingPointSelected,
                      onClear: () {
                        _meetingPointController.clear();

                        setState(() {
                          _selectedMeetingPoint = null;
                          _selectedMeetingPointLabel = null;
                        });
                      },
                      hint: 'Search starting point...',
                    ),

                    const SizedBox(height: 18),

                    _buildWaypoints(),

                    const SizedBox(height: 18),

                    _buildLocationField(
                      label: 'FINAL DESTINATION',
                      controller: _destinationController,
                      selected: _selectedDestination,
                      selectedLabel: _selectedDestinationLabel,
                      results: _destinationSearchResults,
                      loading: _isDestinationSearching,
                      showResults: _showDestinationResults,
                      onSelected: _onDestinationSelected,
                      onClear: () {
                        _destinationController.clear();

                        setState(() {
                          _selectedDestination = null;
                          _selectedDestinationLabel = null;
                        });
                      },
                      hint: 'Search final destination...',
                    ),

                    const SizedBox(height: 18),

                    _buildRouteInfo(),

                    const SizedBox(height: 36),

                    const _SectionLabel(number: '03', title: 'SCHEDULE'),

                    const SizedBox(height: 16),

                    _SelectionTile(
                      icon: CupertinoIcons.calendar,
                      title: _formatDateTime(
                        _departureTime,
                        'SELECT DEPARTURE',
                      ),
                      subtitle: 'Departure date and time',
                      onTap: _pickDepartureTime,
                    ),

                    const SizedBox(height: 14),

                    _ToggleTile(
                      icon: CupertinoIcons.arrow_2_circlepath,
                      title: 'ROUND TRIP',
                      subtitle:
                          'Return to the starting point after reaching the destination.',
                      value: _isRoundTrip,
                      onChanged: (value) {
                        setState(() {
                          _isRoundTrip = value;

                          if (!value) {
                            _returnTime = null;
                          }
                        });
                      },
                    ),

                    if (_isRoundTrip) ...[
                      const SizedBox(height: 14),

                      _SelectionTile(
                        icon: CupertinoIcons.arrow_uturn_left,
                        title: _formatDateTime(_returnTime, 'SELECT RETURN'),
                        subtitle: 'Expected return date and time',
                        onTap: _pickReturnTime,
                      ),
                    ],

                    const SizedBox(height: 36),

                    const _SectionLabel(number: '04', title: 'COST'),

                    const SizedBox(height: 16),

                    _CostField(
                      controller: _fuelController,
                      label: 'FUEL',
                      icon: CupertinoIcons.drop,
                    ),

                    const SizedBox(height: 10),

                    _CostField(
                      controller: _tollController,
                      label: 'TOLLS',
                      icon: CupertinoIcons.car_detailed,
                    ),

                    const SizedBox(height: 10),

                    _CostField(
                      controller: _parkingController,
                      label: 'PARKING',
                      icon: CupertinoIcons.car,
                    ),

                    const SizedBox(height: 10),

                    _CostField(
                      controller: _accommodationController,
                      label: 'ACCOMMODATION',
                      icon: CupertinoIcons.bed_double,
                    ),

                    const SizedBox(height: 10),

                    _CostField(
                      controller: _otherCostController,
                      label: 'OTHER',
                      icon: CupertinoIcons.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    _buildCostSummary(),

                    const SizedBox(height: 36),

                    const _SectionLabel(number: '05', title: 'RIDE DETAILS'),

                    const SizedBox(height: 16),

                    const _SmallLabel(text: 'CATEGORY'),

                    const SizedBox(height: 8),

                    _ChoiceSelector(
                      values: _categories,
                      selected: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    const _SmallLabel(text: 'DIFFICULTY'),

                    const SizedBox(height: 8),

                    _ChoiceSelector(
                      values: _difficulties,
                      selected: _selectedDifficulty,
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    const _SmallLabel(text: 'TERRAIN'),

                    const SizedBox(height: 8),

                    _ChoiceSelector(
                      values: _terrains,
                      selected: _selectedTerrain,
                      onChanged: (value) {
                        setState(() {
                          _selectedTerrain = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _MembersSelector(
                      value: _maxMembers,
                      onChanged: (value) {
                        setState(() {
                          _maxMembers = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    _VisibilitySelector(
                      isPublic: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),

                    const SizedBox(height: 36),

                    const _SectionLabel(
                      number: '06',
                      title: 'SAFETY & REQUIREMENTS',
                    ),

                    const SizedBox(height: 16),

                    _ToggleTile(
                      icon: CupertinoIcons.shield,
                      title: 'HELMET REQUIRED',
                      subtitle: 'Every rider must wear a helmet.',
                      value: _helmetRequired,
                      onChanged: (value) {
                        setState(() {
                          _helmetRequired = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    _ToggleTile(
                      icon: CupertinoIcons.doc_text,
                      title: 'LICENCE REQUIRED',
                      subtitle: 'Riders must have a valid riding licence.',
                      value: _licenceRequired,
                      onChanged: (value) {
                        setState(() {
                          _licenceRequired = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    _InputField(
                      controller: _vehicleRequirementController,
                      label: 'VEHICLE REQUIREMENT',
                      hint:
                          'Adventure motorcycle capable of mountain terrain...',
                      maxLines: 2,
                    ),

                    const SizedBox(height: 14),

                    _InputField(
                      controller: _instructionsController,
                      label: 'ADDITIONAL INSTRUCTIONS',
                      hint: 'Fuel stops, equipment, meeting instructions...',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isPublishing ? null : _publishRide,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF4F4F2),
                          disabledBackgroundColor: const Color(0xFF292929),
                          foregroundColor: const Color(0xFF080808),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                        ),
                        child: _isPublishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF080808),
                                ),
                              )
                            : const Text(
                                'PUBLISH EXPEDITION',
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              CupertinoIcons.chevron_left,
              color: Color(0xFFF4F4F2),
            ),
          ),

          const Expanded(
            child: Text(
              'CREATE EXPEDITION',
              style: TextStyle(
                color: Color(0xFFF4F4F2),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required LatLng? selected,
    required String? selectedLabel,
    required List<dynamic> results,
    required bool loading,
    required bool showResults,
    required ValueChanged2<LatLng, String> onSelected,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 14),
          cursorColor: const Color(0xFFF4F4F2),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }

            if (selected == null) {
              return 'Select a location from the results';
            }

            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4F4F4F), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF111111),
            contentPadding: const EdgeInsets.all(14),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      CupertinoIcons.xmark,
                      size: 15,
                      color: Color(0xFF666666),
                    ),
                  )
                : null,
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _focusedBorder(),
            errorBorder: _errorBorder(),
            focusedErrorBorder: _errorBorder(),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: showResults && controller.text.trim().length >= 2
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InlineSearchResults(
                    places: results,
                    isLoading: loading,
                    onPlaceSelected: onSelected,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),

        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF00E676),
                  size: 13,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    selectedLabel == null || selectedLabel.trim().isEmpty
                        ? 'LOCATION SELECTED'
                        : 'SELECTED · ${selectedLabel.toUpperCase()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 8,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWaypoints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SmallLabel(text: 'WAYPOINTS')),

            TextButton.icon(
              onPressed: _addWaypoint,
              icon: const Icon(CupertinoIcons.plus, size: 13),
              label: const Text(
                'ADD STOP',
                style: TextStyle(fontSize: 9, letterSpacing: 1.5),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF4F4F2),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (_waypoints.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: const Text(
              'No intermediate stops added.',
              style: TextStyle(color: Color(0xFF555555), fontSize: 11),
            ),
          )
        else
          ...List.generate(_waypoints.length, (index) {
            final waypoint = _waypoints[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF444444)),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFFF4F4F2),
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            waypoint.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF4F4F2),
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${waypoint.stopMinutes} MIN STOP',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 8,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () => _removeWaypoint(index),
                      icon: const Icon(
                        CupertinoIcons.trash,
                        size: 15,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.map, color: Color(0xFF777777), size: 18),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROUTE WILL BE CALCULATED AUTOMATICALLY',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _routeDescription(),
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _routeDescription() {
    final waypointCount = _waypoints.length;

    if (_selectedMeetingPoint == null || _selectedDestination == null) {
      return 'Select a starting point and destination to build the route.';
    }

    if (waypointCount == 0) {
      return _isRoundTrip
          ? 'Start → Destination → Start'
          : 'Start → Destination';
    }

    final stopText = waypointCount == 1
        ? '1 waypoint'
        : '$waypointCount waypoints';

    return _isRoundTrip
        ? 'Start → $stopText → Destination → Start'
        : 'Start → $stopText → Destination';
  }

  Widget _buildCostSummary() {
    final total =
        _money(_fuelController) +
        _money(_tollController) +
        _money(_parkingController) +
        _money(_accommodationController) +
        _money(_otherCostController);

    final perRider = _maxMembers > 0 ? total / _maxMembers : total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTIMATED TOTAL',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 8,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'PER RIDER',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 8,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '₹${perRider.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date, String empty) {
    if (date == null) {
      return empty;
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    final month = months[date.month - 1];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} $month ${date.year} • '
        '$hour:$minute $period';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF1A1A1A),
        ),
      );
  }

  OutlineInputBorder _border() {
    return const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF222222)),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF777777)),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
  }

  OutlineInputBorder _errorBorder() {
    return const OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF8B4A4A)),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    );
  }
}

class _WaypointDraft {
  final String id;

  final String title;

  final String locationName;

  final LatLng location;

  final int stopMinutes;

  final int order;

  const _WaypointDraft({
    required this.id,
    required this.title,
    required this.locationName,
    required this.location,
    required this.stopMinutes,
    required this.order,
  });

  _WaypointDraft copyWith({int? order, int? stopMinutes}) {
    return _WaypointDraft(
      id: id,
      title: title,
      locationName: locationName,
      location: location,
      stopMinutes: stopMinutes ?? this.stopMinutes,
      order: order ?? this.order,
    );
  }
}

class _WaypointSearchSheet extends StatefulWidget {
  const _WaypointSearchSheet({
    required this.locationSearchService,
    required this.order,
  });

  final LocationSearchService locationSearchService;

  final int order;

  @override
  State<_WaypointSearchSheet> createState() => _WaypointSearchSheetState();
}

class _WaypointSearchSheetState extends State<_WaypointSearchSheet> {
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;

  List<dynamic> _results = <dynamic>[];

  bool _loading = false;

  LatLng? _selectedLocation;

  String? _selectedName;

  int _stopMinutes = 15;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _results = <dynamic>[];
        _loading = false;
      });

      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final places = await widget.locationSearchService.searchPlaces(query);

      if (!mounted) {
        return;
      }

      if (_controller.text.trim() != query) {
        return;
      }

      setState(() {
        _results = places;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _results = <dynamic>[];
        _loading = false;
      });
    }
  }

  void _select(LatLng location, String name) {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _selectedLocation = location;
      _selectedName = name;
      _controller.text = name;
      _results = <dynamic>[];
    });
  }

  void _save() {
    if (_selectedLocation == null || _selectedName == null) {
      return;
    }

    Navigator.pop(
      context,
      _WaypointDraft(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _selectedName!,
        locationName: _selectedName!,
        location: _selectedLocation!,
        stopMinutes: _stopMinutes,
        order: widget.order,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADD WAYPOINT',
                style: TextStyle(
                  color: Color(0xFFF4F4F2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _controller,
                onChanged: _onChanged,
                style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 14),
                cursorColor: const Color(0xFFF4F4F2),
                decoration: const InputDecoration(
                  hintText: 'Search stop...',
                  hintStyle: TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF222222)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF222222)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF777777)),
                  ),
                ),
              ),

              if (_results.isNotEmpty || _loading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 220,
                    child: InlineSearchResults(
                      places: _results,
                      isLoading: _loading,
                      onPlaceSelected: _select,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              if (_selectedLocation != null)
                _StopDurationSelector(
                  value: _stopMinutes,
                  onChanged: (value) {
                    setState(() {
                      _stopMinutes = value;
                    });
                  },
                ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _selectedLocation == null ? null : _save,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F4F2),
                    disabledBackgroundColor: const Color(0xFF292929),
                    foregroundColor: const Color(0xFF080808),
                  ),
                  child: const Text(
                    'ADD WAYPOINT',
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

class _StopDurationSelector extends StatelessWidget {
  const _StopDurationSelector({required this.value, required this.onChanged});

  final int value;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPECTED STOP',
                  style: TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'How long should riders stop here?',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 10),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 5) : null,
            icon: const Icon(CupertinoIcons.minus, size: 14),
          ),

          Text(
            '$value min',
            style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 12),
          ),

          IconButton(
            onPressed: () => onChanged(value + 5),
            icon: const Icon(CupertinoIcons.plus, size: 14),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;

  final String label;

  final String hint;

  final int maxLines;

  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 14),
          cursorColor: const Color(0xFFF4F4F2),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF4F4F4F), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF111111),
            contentPadding: const EdgeInsets.all(14),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF222222)),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF222222)),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF777777)),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8B4A4A)),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8B4A4A)),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CostField extends StatelessWidget {
  const _CostField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;

  final String label;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF666666)),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ),

        SizedBox(
          width: 110,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 13),
            decoration: const InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(color: Color(0xFF666666)),
              hintText: '0',
              hintStyle: TextStyle(color: Color(0xFF444444)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B8B8B), size: 18),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF4F4F2),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF555555),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final bool value;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B8B8B), size: 18),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFF4F4F2),
            activeTrackColor: const Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSelector extends StatelessWidget {
  const _ChoiceSelector({
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final List<String> values;

  final String selected;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = value == selected;

        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF4F4F2)
                  : const Color(0xFF111111),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF4F4F2)
                    : const Color(0xFF252525),
              ),
            ),
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF080808)
                    : const Color(0xFF888888),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 1.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MembersSelector extends StatelessWidget {
  const _MembersSelector({required this.value, required this.onChanged});

  final int value;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAXIMUM RIDERS',
                  style: TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Maximum riders allowed.',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 11),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: value > 2 ? () => onChanged(value - 1) : null,
            icon: const Icon(CupertinoIcons.minus, size: 14),
          ),

          Text(
            '$value',
            style: const TextStyle(color: Color(0xFFF4F4F2), fontSize: 16),
          ),

          IconButton(
            onPressed: value < 100 ? () => onChanged(value + 1) : null,
            icon: const Icon(CupertinoIcons.plus, size: 14),
          ),
        ],
      ),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({required this.isPublic, required this.onChanged});

  final bool isPublic;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Icon(
            isPublic ? CupertinoIcons.globe : CupertinoIcons.lock,
            color: const Color(0xFF8B8B8B),
            size: 18,
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PUBLIC EXPEDITION',
                  style: TextStyle(
                    color: Color(0xFFF4F4F2),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Anyone in OpenTrail can discover it.',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 11),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: isPublic,
            onChanged: onChanged,
            activeColor: const Color(0xFFF4F4F2),
            activeTrackColor: const Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.number, required this.title});

  final String number;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '[ $number ]',
          style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF4F4F2),
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(child: Divider(color: Color(0xFF202020), height: 1)),
      ],
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 9,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

typedef ValueChanged2<T, U> = void Function(T value, U value2);
