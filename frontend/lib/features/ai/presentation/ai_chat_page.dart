import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/ai/providers/ai_coach_provider.dart';
import 'package:frontend/core/ads/ad_service.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    "Am I eating enough protein?",
    "Suggest a high-protein snack",
    "Analyze my weight progress",
    "Did I drink enough water today?"
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _promptAndSend(String text) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          title: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                "Unlock AI Response",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            "Watch a quick sponsor video to get a detailed response from your AI Health Coach.",
            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.outfit(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                
                // Show Rewarded Ad to user
                AdService.showRewarded(
                  // User watched the ad fully
                  () {
                    ref.read(aiChatProvider.notifier).sendMessage(text);
                    _messageController.clear();
                    _scrollToBottom();
                  },
                  onFailedToLoad: () {
                    // Fallback: Show warning and do not send
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(
                          "Failed to load ad. Please try again.",
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                "Watch Ad & Send",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _promptAndSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Listen to changes in chat history to trigger scrolling
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          "AI Coach",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.darkTextSecondary),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
            },
            tooltip: "Clear Chat",
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history list
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bot, color: AppColors.darkTextSecondary.withOpacity(0.5), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            "No messages yet. Ask something!",
                            style: GoogleFonts.outfit(color: AppColors.darkTextSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role == "user";
                        return _buildChatBubble(msg, isUser);
                      },
                    ),
            ),

            // Loading indicator
            if (chatState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Coach is thinking...",
                      style: GoogleFonts.outfit(
                        color: AppColors.darkTextSecondary,
                        fontSize: 12,
                      ),
                    )
                  ],
                ),
              ),

            // Quick suggestion chips
            if (chatState.messages.length <= 1 && !chatState.isLoading)
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white),
                        ),
                        backgroundColor: AppColors.darkSurface,
                        side: BorderSide(color: AppColors.darkBorder.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          _promptAndSend(suggestion);
                        },
                      ),
                    );
                  },
                ),
              ),

            // Input Bar
            _buildInputBar(chatState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.secondary : AppColors.darkSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.darkBorder.withOpacity(0.3), width: 1),
        ),
        child: Text(
          msg.content,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder.withOpacity(0.4), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isLoading,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ask Fitness Buddy...",
                hintStyle: GoogleFonts.outfit(color: AppColors.darkTextSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: AppColors.darkBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLoading ? AppColors.darkBorder : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLoading ? LucideIcons.loader2 : LucideIcons.sendHorizontal,
                color: isLoading ? AppColors.darkTextSecondary : Colors.black,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
