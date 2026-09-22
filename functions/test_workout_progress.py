import unittest
from workout_progress import workout_completion_ratio, scaled_completion_delta


class WorkoutProgressTest(unittest.TestCase):
    def workout(self, actual=None, kind='reps', target=10, completed=1):
        return {'type': kind, 'baseReps': target, 'baseSeconds': target,
                'intensityFactor': 1, 'schedule': [
                    {'plannedUnits': 1, 'completedUnits': completed, 'actualValue': actual}]}

    def test_repetitions_and_seconds_scale_exactly(self):
        for kind in ('reps', 'time'):
            for actual, ratio in ((0, 0), (1, .1), (5, .5), (10, 1), (20, 1)):
                with self.subTest(kind=kind, actual=actual):
                    value = workout_completion_ratio(self.workout(actual, kind))
                    self.assertEqual(value, ratio)
                    self.assertAlmostEqual(scaled_completion_delta(.3, .6, value), .034 * ratio)

    def test_minimum_reward_is_also_scaled(self):
        self.assertEqual(scaled_completion_delta(.8, .2, .1), .0004)
        self.assertEqual(scaled_completion_delta(.8, .2, 0), 0)

    def test_legacy_completed_and_pending(self):
        self.assertEqual(workout_completion_ratio(self.workout()), 1)
        self.assertEqual(workout_completion_ratio(self.workout(completed=0)), 0)

    def test_unilateral_total_and_round_weighting(self):
        data = self.workout(5)
        data['schedule'][0]['targetValue'] = 20
        self.assertEqual(workout_completion_ratio(data), .25)
        data['schedule'].append({'plannedUnits': 1, 'completedUnits': 0})
        self.assertEqual(workout_completion_ratio(data), .125)

    def test_intensity_and_zero_target(self):
        data = self.workout(10)
        data['intensityFactor'] = 2
        self.assertEqual(workout_completion_ratio(data), .5)
        self.assertEqual(workout_completion_ratio({'schedule': []}), 0)

    def test_two_of_eighteen_do_not_receive_full_125_point_reward(self):
        data = self.workout(2, target=18)
        ratio = workout_completion_ratio(data)
        full_points = scaled_completion_delta(0, .11, 1) / 1.2 * 100
        partial_points = scaled_completion_delta(0, .11, ratio) / 1.2 * 100
        self.assertAlmostEqual(full_points, 1.25)
        self.assertAlmostEqual(partial_points, 1.25 * 2 / 18)
        self.assertEqual(round(partial_points, 2), .14)

if __name__ == '__main__':
    unittest.main()
