import 'package:flutter/material.dart';

import '../models/assistant_chat_message.dart';
import '../models/beauty_product.dart';
import '../services/glow_store.dart';
import '../theme/app_colors.dart';
import '../widgets/layout_widgets.dart';

/// Chat tab. Answers are grounded in the user's own shelf and pass through
/// the safety guard in [AssistantReply.isSafeFor] before being shown.
class GlowAssistantScreen extends StatefulWidget {
  const GlowAssistantScreen({
    super.key,
    required this.products,
    required this.store,
  });

  final List<BeautyProduct> products;
  final GlowStore store;

  @override
  State<GlowAssistantScreen> createState() => _GlowAssistantScreenState();
}

class _GlowAssistantScreenState extends State<GlowAssistantScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();
  final _messages = <AssistantChatMessage>[
    AssistantChatMessage(
      role: 'assistant',
      text:
          'Tell me what your skin feels like today. I will check your current shelf and suggest a simple, safe routine from products you already own.',
    ),
  ];
  var _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        _scrollToLatest();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputFocus.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // The keyboard opening shrinks the viewport after focus is granted, which
    // would otherwise push the newest reply out of sight.
    if (_inputFocus.hasFocus) {
      _scrollToLatest();
    }
  }

  /// Keeps the newest bubble in view.
  ///
  /// Deferred to after the frame so the list has been laid out with the new
  /// message, or with the shorter viewport, before the extent is measured.
  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    // Conversation so far, minus the seeded greeting, which carries no user
    // context and would only spend tokens.
    final history = _messages.skip(1).toList();
    setState(() {
      _controller.clear();
      _messages.add(AssistantChatMessage(role: 'user', text: text));
      _sending = true;
    });
    // Reveal the question and the thinking bubble straight away.
    _scrollToLatest();
    await widget.store.saveChatMessage(role: 'user', text: text);
    final reply = await widget.store.askAssistant(
      message: text,
      products: widget.products,
      history: history,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(
        AssistantChatMessage(
          role: 'assistant',
          text: reply.message,
          safetyNote: reply.safetyNote,
          fromFallback: reply.fromFallback,
        ),
      );
      _sending = false;
    });
    _scrollToLatest();
    await widget.store.saveChatMessage(
      role: 'assistant',
      text: '${reply.message}\n\n${reply.safetyNote}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final usableProducts = widget.products
        .where((item) => item.isRecommendable(DateTime.now()))
        .length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              const AppHeader(
                title: 'Glow Assistant',
                subtitle:
                    'AI skincare guidance based on your current beauty shelf.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$usableProducts usable products available for recommendations.',
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (_sending && index == _messages.length) {
                return const AssistantBubble(
                  message: AssistantChatMessage(
                    role: 'assistant',
                    text: 'Thinking through your shelf...',
                  ),
                );
              }
              return AssistantBubble(message: _messages[index]);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: ink.withValues(alpha: 0.06))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocus,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Example: My skin is red and itchy today',
                      prefixIcon: Icon(Icons.spa_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One chat bubble, right-aligned for the user and left for the assistant.
class AssistantBubble extends StatelessWidget {
  const AssistantBubble({super.key, required this.message});

  final AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ink.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : ink,
                height: 1.35,
              ),
            ),
            if (message.safetyNote != null &&
                message.safetyNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                message.safetyNote!,
                style: TextStyle(
                  color: ink.withValues(alpha: 0.6),
                  height: 1.3,
                  fontSize: 12,
                ),
              ),
            ],
            if (message.fromFallback) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 13,
                    color: secondary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Offline guidance',
                    style: TextStyle(
                      color: secondary.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
