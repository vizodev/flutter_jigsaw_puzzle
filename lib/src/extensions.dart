import 'dart:math' show Random;

import 'package:uuid/uuid.dart';

// ignore_for_file: public_member_api_docs

extension SuperRandom on Random {

  /// Generate new random using [Uuid] V4 seed
  Random toSuperRandom() {
    return Random(const Uuid().v4().hashCode);
  }
}