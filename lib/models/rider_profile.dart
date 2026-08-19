class HeartRateZones {
  final int z1MinBpm;
  final int z2MinBpm;
  final int z3MinBpm;
  final int z4MinBpm;
  final int z5MinBpm;

  const HeartRateZones({
    required this.z1MinBpm,
    required this.z2MinBpm,
    required this.z3MinBpm,
    required this.z4MinBpm,
    required this.z5MinBpm,
  }) : assert(z1MinBpm >= 0),
       assert(z1MinBpm <= z2MinBpm),
       assert(z2MinBpm <= z3MinBpm),
       assert(z3MinBpm <= z4MinBpm),
       assert(z4MinBpm <= z5MinBpm);
}

/// Physical/fitness profile. Authentication identity is stored separately.
class RiderProfile {
  final double weightKg;
  final int ftpWatts;
  final int? hrMaxBpm;
  final HeartRateZones? hrZones;
  final double bikeWeightKg;
  final double cda;
  final double crr;
  final double drivetrainEfficiency;
  final Map<int, int>? powerCurveWatts;

  const RiderProfile({
    required this.weightKg,
    required this.ftpWatts,
    this.hrMaxBpm,
    this.hrZones,
    this.bikeWeightKg = 8,
    this.cda = 0.32,
    this.crr = 0.004,
    this.drivetrainEfficiency = 0.975,
    this.powerCurveWatts,
  }) : assert(weightKg > 0),
       assert(ftpWatts > 0),
       assert(bikeWeightKg >= 0),
       assert(cda > 0),
       assert(crr > 0),
       assert(drivetrainEfficiency > 0 && drivetrainEfficiency <= 1);

  double get systemMassKg => weightKg + bikeWeightKg;

  RiderProfile copyWith({
    double? weightKg,
    int? ftpWatts,
    int? hrMaxBpm,
    HeartRateZones? hrZones,
    double? bikeWeightKg,
    double? cda,
    double? crr,
    double? drivetrainEfficiency,
    Map<int, int>? powerCurveWatts,
  }) => RiderProfile(
        weightKg: weightKg ?? this.weightKg,
        ftpWatts: ftpWatts ?? this.ftpWatts,
        hrMaxBpm: hrMaxBpm ?? this.hrMaxBpm,
        hrZones: hrZones ?? this.hrZones,
        bikeWeightKg: bikeWeightKg ?? this.bikeWeightKg,
        cda: cda ?? this.cda,
        crr: crr ?? this.crr,
        drivetrainEfficiency:
            drivetrainEfficiency ?? this.drivetrainEfficiency,
        powerCurveWatts: powerCurveWatts ?? this.powerCurveWatts,
      );
}
