import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key});
  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, String>> _msgs = [];
  bool _sending = false, _aiOn = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient().get('/mentor/history');
      if (r.data['success'] == true) {
        setState(() => _msgs = (r.data['data'] as List).map<Map<String, String>>((m) => {'role': m['role'] ?? '', 'content': m['content'] ?? ''}).toList());
      }
    } catch (_) {}

    try {
      final s = await ApiClient().get('/ai/status');
      if (s.data['success'] == true) {
        setState(() => _aiOn = s.data['data']['available'] ?? true);
      }
    } catch (_) {}

    _scrollEnd();
  }

  Future<void> _send() async {
    final t = _controller.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() { _msgs.add({'role': 'USER', 'content': t}); _sending = true; });
    _controller.clear();
    _scrollEnd();
    try {
      final r = await ApiClient().post('/mentor/chat', data: {'message': t});
      if (r.data['success'] == true) {
        final d = r.data['data'];
        setState(() { _msgs.add({'role': 'ASSISTANT', 'content': d['reply'] ?? ''}); if (d['isAI'] == false) _aiOn = false; });
      }
    } catch (_) {
      setState(() => _msgs.add({'role': 'ASSISTANT', 'content': 'Could not connect. Please try again.'}));
    }
    setState(() => _sending = false);
    _scrollEnd();
  }

  void _scrollEnd() => Future.delayed(const Duration(milliseconds: 100), () { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });

  @override
  void dispose() { _controller.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KarmaColors.background,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(gradient: const LinearGradient(colors: [KarmaColors.primary, KarmaColors.good]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.psychology, size: 18, color: Colors.white)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Karma Mentor', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(_aiOn ? 'AI-Powered Guide' : 'Offline Mode', style: TextStyle(fontSize: 10, color: _aiOn ? KarmaColors.good : KarmaColors.warning)),
          ]),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.delete_outline, color: KarmaColors.textHint), onPressed: () async { await ApiClient().delete('/mentor/history'); setState(() => _msgs.clear()); })],
      ),
      body: Column(children: [
        if (!_aiOn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: KarmaColors.warning.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: KarmaColors.warning),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI mentor is offline. Responses are pre-written.',
                    style: TextStyle(fontSize: 11, color: KarmaColors.warning),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider).resetAIStatus();
                    _load();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: KarmaColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _msgs.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.psychology, size: 64, color: KarmaColors.surfaceLighter), const SizedBox(height: 16), Text('Ask for guidance', style: GoogleFonts.outfit(fontSize: 20, color: KarmaColors.textSecondary))]))
          : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(16), itemCount: _msgs.length + (_sending ? 1 : 0), itemBuilder: (_, i) {
              if (i == _msgs.length) return Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: KarmaColors.surface, borderRadius: BorderRadius.circular(18)), child: const Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: KarmaColors.primary, strokeWidth: 2)), SizedBox(width: 10), Text('Thinking...', style: TextStyle(color: KarmaColors.textHint))])));
              final m = _msgs[i]; final isU = m['role'] == 'USER';
              return Align(alignment: isU ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                decoration: BoxDecoration(color: isU ? KarmaColors.primary : KarmaColors.surface, borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isU ? 18 : 4), bottomRight: Radius.circular(isU ? 4 : 18))),
                child: Text(m['content'] ?? '', style: TextStyle(fontSize: 14, color: isU ? Colors.white : KarmaColors.textPrimary, height: 1.5)),
              ));
            })),
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 8, MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(color: KarmaColors.surface, border: Border(top: BorderSide(color: KarmaColors.surfaceLighter.withValues(alpha: 0.5)))),
          child: Row(children: [
            Expanded(child: TextField(controller: _controller, style: const TextStyle(color: KarmaColors.textPrimary), maxLines: 3, minLines: 1, onSubmitted: (_) => _send(), decoration: InputDecoration(hintText: 'Ask your mentor...', filled: true, fillColor: KarmaColors.surfaceLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)))),
            const SizedBox(width: 8),
            GestureDetector(onTap: _send, child: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [KarmaColors.primary, KarmaColors.primaryLight]), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.send, color: Colors.white, size: 20))),
          ]),
        ),
      ]),
    );
  }
}
