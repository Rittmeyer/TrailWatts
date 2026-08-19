import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The five training-intensity zones, shared across map, calendar, workout
/// builder and history (Constitution Article VII - one taxonomy, not one
/// per screen).
enum Zone { recuperacao, resistencia, tempo, limiar, vo2max }

extension ZoneX on Zone {
  String get code => switch (this) {
        Zone.recuperacao => 'Z1',
        Zone.resistencia => 'Z2',
        Zone.tempo => 'Z3',
        Zone.limiar => 'Z4',
        Zone.vo2max => 'Z5',
      };

  String get label => switch (this) {
        Zone.recuperacao => 'Recuperação',
        Zone.resistencia => 'Resistência',
        Zone.tempo => 'Tempo',
        Zone.limiar => 'Limiar',
        Zone.vo2max => 'VO2max',
      };

  Color get color => switch (this) {
        Zone.recuperacao => AppColors.zone1,
        Zone.resistencia => AppColors.zone2,
        Zone.tempo => AppColors.zone3,
        Zone.limiar => AppColors.zone4,
        Zone.vo2max => AppColors.zone5,
      };

  /// e.g. "Recuperacao (Z1)" - matches the zone <select> options on the
  /// Criar Treino screens (02a/02b) in the HTML prototype.
  String get pickerLabel => '$label ($code)';
}
