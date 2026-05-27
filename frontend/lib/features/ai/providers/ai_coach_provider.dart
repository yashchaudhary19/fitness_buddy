import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_service.dart';
import 'package:frontend/core/constants/api_constants.dart';

// Chat message structure
class ChatMessage {
  final String role; // "user" or "assistant"
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

// Chat state holding messages list and sending state
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Notifier to handle user chat actions
class AiChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService;

  AiChatNotifier(this._apiService) : super(ChatState(messages: [])) {
    // Add an initial greeting message from the coach
    state = ChatState(messages: [
      ChatMessage(
        role: "assistant",
        content: "Hello! I'm your AI health & fitness coach. I have analyzed your recent logs and targets. Ask me anything about your diet, workouts, or weight trends!",
      )
    ]);
  }

  void clearChat() {
    state = ChatState(messages: [
      ChatMessage(
        role: "assistant",
        content: "Hello! I'm your AI health & fitness coach. I have analyzed your recent logs and targets. Ask me anything about your diet, workouts, or weight trends!",
      )
    ]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: "user", content: text);
    final currentMessages = [...state.messages, userMessage];

    state = state.copyWith(
      messages: currentMessages,
      isLoading: true,
    );

    try {
      final response = await _apiService.post(
        ApiConstants.aiChat,
        data: {
          'messages': currentMessages.map((m) => m.toJson()).toList(),
        },
      );

      if (response.success && response.data != null) {
        final replyText = response.data['response'] as String? ?? "Sorry, I couldn't generate a reply.";
        state = state.copyWith(
          messages: [...currentMessages, ChatMessage(role: "assistant", content: replyText)],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? "Failed to get reply from coach.",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// Providers definition
final aiChatProvider = StateNotifierProvider<AiChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AiChatNotifier(apiService);
});

// Daily Nutrition Debrief structures
class DailyDebrief {
  final String summary;
  final List<String> deficits;
  final List<String> tweaks;

  DailyDebrief({
    required this.summary,
    required this.deficits,
    required this.tweaks,
  });

  factory DailyDebrief.fromJson(Map<String, dynamic> json) {
    return DailyDebrief(
      summary: json['summary'] as String? ?? "",
      deficits: List<String>.from(json['deficits'] ?? []),
      tweaks: List<String>.from(json['tweaks'] ?? []),
    );
  }
}

final aiDebriefProvider = FutureProvider.family<DailyDebrief, String>((ref, dateStr) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get(
    ApiConstants.aiDebrief,
    queryParameters: {'date_str': dateStr},
  );
  
  if (response.success && response.data != null) {
    return DailyDebrief.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw ApiException(response.error ?? "Failed to fetch nutrition debrief.");
  }
});

// Weight trend interpretation structures
class WeightInterpretation {
  final String interpretation;
  final String suggestion;

  WeightInterpretation({
    required this.interpretation,
    required this.suggestion,
  });

  factory WeightInterpretation.fromJson(Map<String, dynamic> json) {
    return WeightInterpretation(
      interpretation: json['interpretation'] as String? ?? "",
      suggestion: json['suggestion'] as String? ?? "",
    );
  }
}

final aiWeightInterpretationProvider = FutureProvider<WeightInterpretation>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get(ApiConstants.aiWeightInterpretation);
  
  if (response.success && response.data != null) {
    return WeightInterpretation.fromJson(response.data as Map<String, dynamic>);
  } else {
    throw ApiException(response.error ?? "Failed to fetch weight trend analysis.");
  }
});
