import 'package:flutter/material.dart';
import 'package:rize/globals.dart' as globals;
import 'package:rize/helpers/workout_library_helpers.dart';
import 'package:rize/types/workout.dart';
import 'package:rize/base_widgets.dart';
import 'package:rize/widgets/workout_library_widgets.dart';

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
    return filterWorkoutLibrary(
      globals.workoutLibrary,
      _searchQuery,
    );
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
                        key: ValueKey<String>(
                          'results-${_searchQuery.trim()}',
                        ),
                        child: ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            28,
                          ),
                          itemCount: workouts.length,
                          separatorBuilder: (
                            final BuildContext context,
                            final int index,
                          ) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (
                            final BuildContext context,
                            final int index,
                          ) {
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