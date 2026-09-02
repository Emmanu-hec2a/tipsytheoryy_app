import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/ai_assistant_provider.dart';
import '../services/ai_voice_service.dart';
import '../core/theme.dart';

class TheoryAIFab extends StatefulWidget {
  const TheoryAIFab({super.key});

  @override
  State<TheoryAIFab> createState() => _TheoryAIFabState();
}

class _TheoryAIFabState extends State<TheoryAIFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Actions are now handled in the provider with context
  }

  // Handled in provider

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIAssistantProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (aiProvider.state != VoiceState.idle)
          _buildStatusBubble(aiProvider),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => aiProvider.toggleListening(context),
          child: ScaleTransition(
            scale: aiProvider.state == VoiceState.listening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: aiProvider.state == VoiceState.idle ? 60 : 70,
              height: aiProvider.state == VoiceState.idle ? 60 : 70,
              decoration: BoxDecoration(
                color: _getFabColor(aiProvider.state),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getFabColor(aiProvider.state).withValues(alpha: 0.4),
                    blurRadius: aiProvider.state == VoiceState.listening ? 20 : 15,
                    spreadRadius: aiProvider.state == VoiceState.listening ? 5 : 2,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: _buildFabIcon(aiProvider.state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBubble(AIAssistantProvider provider) {
    String text = "";
    switch (provider.state) {
      case VoiceState.listening: text = "Listening..."; break;
      case VoiceState.processing: text = "Thinking..."; break;
      case VoiceState.speaking: text = provider.aiResponseText; break;
      case VoiceState.error:
        text = provider.aiResponseText.isNotEmpty
            ? provider.aiResponseText
            : "Connection lost...";
        break;
      default: text = "";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(right: 8),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFabIcon(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return const Center(
          child: Icon(Icons.mic, color: Colors.white, size: 30),
        );
      case VoiceState.processing:
        return Center(
          child: Lottie.network(
            'https://lottie.host/57527632-4d76-47a2-9e32-2a7873832d2c/Sj1v0oP9G1.json', // Sophisticated pulse/dots
            width: 40,
            height: 40,
          ),
        );
      case VoiceState.speaking:
        return Center(
          child: Lottie.network(
            'https://lottie.host/79a8344e-1b83-4903-889b-987050369806/y9o48F0W9f.json', // Voice visualizer
            width: 35,
            height: 35,
          ),
        );
      default:
        return Center(
          child: Image.asset(
            'assets/images/theory_logo_small.png',
            width: 30,
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
        );
    }
  }

  Color _getFabColor(VoiceState state) {
    switch (state) {
      case VoiceState.listening: return Colors.redAccent;
      case VoiceState.processing: return AppTheme.primaryColor;
      case VoiceState.speaking: return AppTheme.accentColor;
      case VoiceState.error: return Colors.grey;
      default: return AppTheme.primaryColor;
    }
  }
}
