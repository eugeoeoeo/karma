import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../app/providers.dart';

class VoiceLogScreen extends ConsumerStatefulWidget {
  const VoiceLogScreen({super.key});

  @override
  ConsumerState<VoiceLogScreen> createState() => _VoiceLogScreenState();
}

class _VoiceLogScreenState extends ConsumerState<VoiceLogScreen> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _speechAvailable = false;
  String _text = '';
  String _actionType = 'GOOD';
  Map<String, dynamic>? _analysisResult;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _waveController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startListening() {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available on this device')));
      return;
    }

    _speech.listen(
      onResult: (result) => setState(() => _text = result.recognizedWords),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
    );

    setState(() {
      _isListening = true;
      _analysisResult = null;
    });
    _pulseController.repeat();
    _waveController.repeat();
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _pulseController.stop();
    _waveController.stop();

    if (_text.isNotEmpty) _analyzeAction();
  }

  Future<void> _analyzeAction() async {
    setState(() => _isAnalyzing = true);
    try {
      final response = await ApiClient().post('/actions', data: {'actionText': _text, 'actionType': _actionType, 'source': 'VOICE'});
      if (response.data['success'] == true) {
        setState(() => _analysisResult = response.data['data']);
        ref.invalidate(dashboardProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analysis failed')));
    }
    setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KarmaColors.background,
      appBar: AppBar(
        title: const Text('Voice Log'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Action type toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: Container(
                decoration: BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _actionType = 'GOOD'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _actionType == 'GOOD' ? KarmaColors.good.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text('✨ Good', style: TextStyle(color: _actionType == 'GOOD' ? KarmaColors.good : KarmaColors.textHint, fontWeight: FontWeight.w600))),
                    ),
                  )),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _actionType = 'NEGATIVE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _actionType == 'NEGATIVE' ? KarmaColors.negative.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text('🌱 Growth', style: TextStyle(color: _actionType == 'NEGATIVE' ? KarmaColors.negative : KarmaColors.textHint, fontWeight: FontWeight.w600))),
                    ),
                  )),
                ]),
              ),
            ),

            // Transcribed text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: _analysisResult != null
                      ? _buildAnalysisCard()
                      : _isAnalyzing
                          ? Column(mainAxisSize: MainAxisSize.min, children: [
                              const CircularProgressIndicator(color: KarmaColors.primary),
                              const SizedBox(height: 20),
                              Text('Analyzing your action...', style: TextStyle(color: KarmaColors.textSecondary)),
                            ])
                          : Text(
                              _text.isEmpty ? (_isListening ? 'Listening...' : 'Tap the mic and speak your action') : _text,
                              style: GoogleFonts.inter(
                                fontSize: _text.isEmpty ? 18 : 20,
                                color: _text.isEmpty ? KarmaColors.textHint : KarmaColors.textPrimary,
                                fontWeight: _text.isEmpty ? FontWeight.w400 : FontWeight.w500,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                ),
              ),
            ),

            // Mic button
            if (_analysisResult == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = _isListening ? 1.0 + sin(_pulseController.value * pi * 2) * 0.08 : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _isListening
                                ? [KarmaColors.negative, KarmaColors.negativeLight]
                                : [KarmaColors.primary, KarmaColors.primaryLight]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: (_isListening ? KarmaColors.negative : KarmaColors.primary).withValues(alpha: 0.5),
                              blurRadius: _isListening ? 30 : 20,
                              offset: const Offset(0, 8),
                            )],
                          ),
                          child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Done button after analysis
            if (_analysisResult != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
                child: Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => setState(() { _text = ''; _analysisResult = null; }),
                    style: OutlinedButton.styleFrom(foregroundColor: KarmaColors.textSecondary, side: const BorderSide(color: KarmaColors.surfaceLighter), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Log Another'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GradientButton(text: 'Done', onPressed: () => Navigator.pop(context))),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = _analysisResult!['analysis'] ?? _analysisResult!['aiAnalysis'] ?? {};
    final isAI = analysis['isAI'] ?? false;
    final virtues = (analysis['virtues'] ?? analysis['v'] ?? []) as List;
    final insight = analysis['insight'] ?? analysis['s'] ?? '';

    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AIStatusBadge(isAI: isAI),
        const SizedBox(height: 16),
        const Icon(Icons.check_circle, color: KarmaColors.good, size: 48),
        const SizedBox(height: 12),
        Text('Action Logged!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: KarmaColors.textPrimary)),
        const SizedBox(height: 20),
        if (virtues.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: virtues.map<Widget>((v) {
            final name = v['name'] ?? v['n'] ?? '';
            final impact = v['impact'] ?? v['i'] ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: KarmaColors.getVirtueColor(name).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$name ${impact > 0 ? '+$impact' : '$impact'}', style: TextStyle(color: KarmaColors.getVirtueColor(name), fontWeight: FontWeight.w600, fontSize: 13)),
            );
          }).toList()),
        if (insight.toString().isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(insight.toString(), style: const TextStyle(fontSize: 14, color: KarmaColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

