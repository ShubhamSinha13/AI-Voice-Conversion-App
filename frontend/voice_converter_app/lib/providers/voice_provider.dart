import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

/// Voice state
class VoiceState {
  final List<Voice> predefinedVoices;
  final List<Voice> customVoices;
  final Voice? selectedVoice;
  final bool isLoading;
  final String? error;

  VoiceState({
    this.predefinedVoices = const [],
    this.customVoices = const [],
    this.selectedVoice,
    this.isLoading = false,
    this.error,
  });

  VoiceState copyWith({
    List<Voice>? predefinedVoices,
    List<Voice>? customVoices,
    Voice? selectedVoice,
    bool? isLoading,
    String? error,
  }) {
    return VoiceState(
      predefinedVoices: predefinedVoices ?? this.predefinedVoices,
      customVoices: customVoices ?? this.customVoices,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Voice notifier
class VoiceNotifier extends StateNotifier<VoiceState> {
  final ApiService apiService;

  VoiceNotifier(this.apiService) : super(VoiceState());

  /// Load predefined voices
  Future<void> loadPredefinedVoices() async {
    try {
      state = state.copyWith(isLoading: true);
      final voices = await apiService.getPredefinedVoices();
      final voiceList = (voices as List)
          .map((v) => Voice.fromJson(v as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        predefinedVoices: voiceList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Load user's custom voices
  Future<void> loadCustomVoices(String token) async {
    try {
      state = state.copyWith(isLoading: true);
      final voices = await apiService.getMyVoices(token: token);
      final voiceList = (voices as List)
          .map((v) => Voice.fromJson(v as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        customVoices: voiceList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Select voice for use
  void selectVoice(Voice voice) {
    state = state.copyWith(selectedVoice: voice);
  }

  /// Add new custom voice
  Future<void> createVoice({
    required String name,
    required String userDefinedName,
    required String token,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await apiService.createVoice(
        name: name,
        userDefinedName: userDefinedName,
        token: token,
      );
      final newVoice = Voice.fromJson(response);
      state = state.copyWith(
        customVoices: [...state.customVoices, newVoice],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Add sample to voice
  Future<void> addVoiceSample({
    required int voiceId,
    required String filePath,
    required String token,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await apiService.addVoiceSample(
        voiceId: voiceId,
        filePath: filePath,
        token: token,
      );

      // Update custom voices with new accuracy
      final updatedVoices = state.customVoices.map((v) {
        if (v.id == voiceId) {
          return v.copyWith(
            sampleCount: response['sample_count'] ?? v.sampleCount,
            accuracyPercentage:
                response['accuracy_percentage'] ?? v.accuracyPercentage,
          );
        }
        return v;
      }).toList();

      state = state.copyWith(
        customVoices: updatedVoices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Voice state provider
final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final apiService = ApiService();
  return VoiceNotifier(apiService);
});

/// Get all voices (predefined + custom)
final allVoicesProvider = Provider<List<Voice>>((ref) {
  final voiceState = ref.watch(voiceProvider);
  return [...voiceState.predefinedVoices, ...voiceState.customVoices];
});

/// Get custom voices only
final customVoicesProvider = Provider<List<Voice>>((ref) {
  return ref.watch(voiceProvider).customVoices;
});

/// Get predefined voices only
final predefinedVoicesProvider = Provider<List<Voice>>((ref) {
  return ref.watch(voiceProvider).predefinedVoices;
});

/// Get selected voice
final selectedVoiceProvider = Provider<Voice?>((ref) {
  return ref.watch(voiceProvider).selectedVoice;
});
