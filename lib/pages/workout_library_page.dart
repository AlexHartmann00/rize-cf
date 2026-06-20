import 'package:flutter/material.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/workout_library_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/widgets/workout_library_widgets.dart';
import 'package:rize/widgets/pro_upgrade_cta.dart';

class WorkoutLibraryPage extends StatefulWidget {
  const WorkoutLibraryPage({super.key});

  @override
  State<WorkoutLibraryPage> createState() => _WorkoutLibraryPageState();
}

class _WorkoutLibraryPageState extends State<WorkoutLibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  bool get _hasSearchQuery => _searchQuery.trim().isNotEmpty;

  List<Workout> get _filteredWorkouts {
    final List<Workout> accessible = availableWorkoutsForUser(
      workouts: globals.workoutLibrary,
      intensityScore: globals.userData?.intensityScore ?? 0,
      isPro: globals.userData?.isPro == true,
    );
    return filterWorkoutLibrary(accessible, _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(final String value) {
    if (value == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    if (_searchQuery.isEmpty) {
      return;
    }

    setState(() {
      _searchQuery = '';
    });

    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(final BuildContext context) {
    final List<Workout> workouts = _filteredWorkouts;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: <Widget>[
                    WorkoutLibraryHeader(
                      visibleWorkoutCount: workouts.length,
                      totalWorkoutCount: globals.workoutLibrary.length,
                      isSearching: _hasSearchQuery,
                    ),
                    const SizedBox(height: 18),
                    WorkoutLibrarySearchField(
                      controller: _searchController,
                      hasQuery: _hasSearchQuery,
                      onChanged: _handleSearchChanged,
                      onClear: _clearSearch,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: workouts.isEmpty
                    ? WorkoutLibraryEmptyState(
                        key: const ValueKey<String>('empty'),
                        query: _searchQuery.trim(),
                        onClear: _clearSearch,
                      )
                    : Scrollbar(
                        key: ValueKey<String>('results-${_searchQuery.trim()}'),
                        child: ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          itemCount:
                              workouts.length +
                              (globals.userData?.isPro == true ? 0 : 1),
                          separatorBuilder:
                              (final BuildContext context, final int index) {
                                return const SizedBox(height: 12);
                              },
                          itemBuilder: (final BuildContext context, final int index) {
                            if (index == workouts.length) {
                              final int remaining =
                                  globals.workoutLibrary.length -
                                  workouts.length;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => showProUpgradeSheet(
                                    context,
                                    source: 'library_locked_card',
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Ink(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.workspace_premium_rounded,
                                          color: Color(0xFFFFB27D),
                                          size: 30,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$remaining weitere Übungen mit RIZE Pro',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        const Text(
                                          'Alle Übungen für 3,99 € pro Monat freischalten.',
                                          style: TextStyle(
                                            color: Colors.white60,
                                          ),
                                        ),
                                        const SizedBox(height: 13),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              'RIZE PRO ANSEHEN',
                                              style: TextStyle(
                                                color: Color(0xFF7ED8FF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Color(0xFF7ED8FF),
                                              size: 17,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 900,
                                ),
                                child: WorkoutSummaryWidget(
                                  workout: workouts[index],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
