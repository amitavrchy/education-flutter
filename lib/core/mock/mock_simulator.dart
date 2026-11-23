import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../settings/app_settings.dart';

/// Default latency of mock calls. Tests override it with [Duration.zero].
final mockLatencyProvider = Provider<Duration>((ref) => const Duration(milliseconds: 350));

/// Simulates the network for mock repositories: latency, offline mode and injected
/// server errors, all driven by the demo toggles in settings.
class MockSimulator {
  MockSimulator({required this.latency, required this.settings});

  final Duration latency;
  final AppSettings Function() settings;

  bool get isOffline => settings().simulateOffline;

  /// Runs [body] after the simulated latency.
  ///
  /// [requiresNetwork] = false for data that is available offline (downloads, local notes).
  Future<T> run<T>(
    FutureOr<T> Function() body, {
    bool requiresNetwork = true,
    double latencyFactor = 1,
  }) async {
    final current = settings();
    if (requiresNetwork && current.simulateOffline) {
      await _wait(0.3);
      throw const ApiException.offline();
    }
    await _wait(requiresNetwork ? latencyFactor : 0.2);
    if (requiresNetwork && current.simulateErrors) throw const ApiException.simulated();
    return body();
  }

  Future<void> _wait(double factor) async {
    if (latency == Duration.zero) return;
    await Future<void>.delayed(latency * factor);
  }

  /// Emits [chunks] one by one, for simulated streaming (AI answers).
  Stream<String> stream(List<String> chunks, {Duration perChunk = const Duration(milliseconds: 28)}) async* {
    final current = settings();
    if (current.simulateOffline) throw const ApiException.offline();
    await _wait(1.2);
    if (current.simulateErrors) throw const ApiException.simulated();
    for (final chunk in chunks) {
      if (latency != Duration.zero) await Future<void>.delayed(perChunk);
      yield chunk;
    }
  }
}

final mockSimulatorProvider = Provider<MockSimulator>(
  (ref) => MockSimulator(
    latency: ref.watch(mockLatencyProvider),
    settings: () => ref.read(appSettingsProvider),
  ),
);
