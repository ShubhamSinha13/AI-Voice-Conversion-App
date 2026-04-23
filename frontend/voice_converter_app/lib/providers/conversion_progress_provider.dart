import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Conversion status states
enum ConversionStatus {
  idle,
  uploading,
  downloadingModel,
  processing,
  downloadingAudio,
  complete,
  error,
}

/// Conversion progress data
class ConversionProgress {
  final ConversionStatus status;
  final double progress; // 0.0 to 1.0
  final String currentStep;
  final Duration elapsedTime;
  final Duration estimatedRemainingTime;
  final String? errorMessage;

  ConversionProgress({
    required this.status,
    required this.progress,
    required this.currentStep,
    required this.elapsedTime,
    required this.estimatedRemainingTime,
    this.errorMessage,
  });

  /// Get user-friendly status text
  String get statusText {
    switch (status) {
      case ConversionStatus.idle:
        return 'Ready';
      case ConversionStatus.uploading:
        return 'Uploading file...';
      case ConversionStatus.downloadingModel:
        return 'Downloading ML model (first time only)...';
      case ConversionStatus.processing:
        return 'Processing audio...';
      case ConversionStatus.downloadingAudio:
        return 'Downloading converted audio...';
      case ConversionStatus.complete:
        return 'Conversion complete!';
      case ConversionStatus.error:
        return 'Error: ${errorMessage ?? "Unknown error"}';
    }
  }

  /// Format time duration
  String get elapsedTimeStr {
    final minutes = elapsedTime.inMinutes;
    final seconds = elapsedTime.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get estimatedRemainingStr {
    if (estimatedRemainingTime.isNegative ||
        status == ConversionStatus.complete) {
      return '--:--';
    }
    final minutes = estimatedRemainingTime.inMinutes;
    final seconds = estimatedRemainingTime.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// State notifier for conversion progress
class ConversionProgressNotifier extends StateNotifier<ConversionProgress> {
  late DateTime _startTime;

  ConversionProgressNotifier()
      : super(ConversionProgress(
          status: ConversionStatus.idle,
          progress: 0.0,
          currentStep: 'Ready',
          elapsedTime: Duration.zero,
          estimatedRemainingTime: Duration.zero,
        ));

  /// Start a new conversion
  void start({String quality = 'basic'}) {
    _startTime = DateTime.now();

    // Estimate time based on quality
    final multiplier = {
          'basic': 1.0,
          'ml': 3.0,
          'rvc': 8.0,
        }[quality] ??
        1.0;

    const baseTime = Duration(seconds: 5);
    final estimatedTime = Duration(
      seconds: (baseTime.inSeconds * multiplier).toInt(),
    );

    updateStatus(
      status: ConversionStatus.uploading,
      progress: 0.05,
      step: 'Uploading file...',
      estimatedTotal: estimatedTime,
    );
  }

  /// Update conversion status
  void updateStatus({
    required ConversionStatus status,
    double progress = 0.0,
    String step = '',
    Duration? estimatedTotal,
  }) {
    final elapsed = DateTime.now().difference(_startTime);
    final remaining =
        estimatedTotal != null ? estimatedTotal - elapsed : Duration.zero;

    state = ConversionProgress(
      status: status,
      progress: progress.clamp(0.0, 1.0),
      currentStep: step.isEmpty ? status.toString().split('.').last : step,
      elapsedTime: elapsed,
      estimatedRemainingTime: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  /// Mark conversion as complete
  void complete() {
    final elapsed = DateTime.now().difference(_startTime);
    state = ConversionProgress(
      status: ConversionStatus.complete,
      progress: 1.0,
      currentStep: 'Conversion complete!',
      elapsedTime: elapsed,
      estimatedRemainingTime: Duration.zero,
    );
  }

  /// Mark conversion as failed
  void error(String message) {
    state = ConversionProgress(
      status: ConversionStatus.error,
      progress: 0.0,
      currentStep: 'Error',
      elapsedTime: DateTime.now().difference(_startTime),
      estimatedRemainingTime: Duration.zero,
      errorMessage: message,
    );
  }

  /// Reset to idle state
  void reset() {
    state = ConversionProgress(
      status: ConversionStatus.idle,
      progress: 0.0,
      currentStep: 'Ready',
      elapsedTime: Duration.zero,
      estimatedRemainingTime: Duration.zero,
    );
  }
}

/// Provider for conversion progress
final conversionProgressProvider =
    StateNotifierProvider<ConversionProgressNotifier, ConversionProgress>(
  (ref) => ConversionProgressNotifier(),
);
