import 'package:flutter/material.dart';

import '../models/assistant_chat_message.dart';
import '../models/beauty_product.dart';
import '../services/glow_store.dart';
import '../theme/app_colors.dart';
import '../widgets/layout_widgets.dart';

/// Chat tab. Gemini answers are grounded against the user's usable shelf
/// before being shown.
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
  final _messages = <AssistantChatMessage>[];
  var _sending = false;
  var _loadingHistory = true;
  var _showingWelcome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentConversation();
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        _scrollToLatest();
      }
    });
  }

  Future<void> _loadRecentConversation() async {
    final history = await widget.store.loadRecentChatMessages();
    if (!mounted) {
      return;
    }
    setState(() {
      _messages
        ..clear()
        ..addAll(history);
      _loadingHistory = false;
      if (_messages.isEmpty) {
        _showingWelcome = true;
        _messages.add(
          AssistantChatMessage(
            role: 'assistant',
            text:
                'Tell me what your skin feels like today. I will check your current shelf and suggest a simple, safe routine from products you already own.',
            createdAt: DateTime.now(),
          ),
        );
      }
    });
    _scrollToLatest();
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
    // The seeded greeting is visual-only; it carries no user context and is
    // not replayed to Gemini.
    final history = _showingWelcome ? _messages.skip(1).toList() : _messages;
    final questionTime = DateTime.now();
    setState(() {
      _controller.clear();
      _messages.add(
        AssistantChatMessage(role: 'user', text: text, createdAt: questionTime),
      );
      _showingWelcome = false;
      _sending = true;
    });
    // Reveal the question and the thinking bubble straight away.
    _scrollToLatest();
    await widget.store.saveChatMessage(
      role: 'user',
      text: text,
      createdAt: questionTime,
    );
    final reply = await widget.store.askAssistant(
      message: text,
      products: widget.products,
      history: history,
    );
    if (!mounted) {
      return;
    }
    final replyTime = DateTime.now();
    setState(() {
      _messages.add(
        AssistantChatMessage(
          role: 'assistant',
          text: reply.message,
          createdAt: replyTime,
          safetyNote: reply.safetyNote,
          fromFallback: reply.fromFallback,
          safetyFallback: reply.safetyFallback,
          quotaLimited: reply.quotaLimited,
        ),
      );
      _sending = false;
    });
    _scrollToLatest();
    await widget.store.saveChatMessage(
      role: 'assistant',
      text: reply.message,
      createdAt: replyTime,
      safetyNote: reply.safetyNote,
      fromFallback: reply.fromFallback,
      safetyFallback: reply.safetyFallback,
      quotaLimited: reply.quotaLimited,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    '24-hour conversation',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Older messages clear automatically.',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.48),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
          child: _loadingHistory
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    for (var index = 0; index < _messages.length; index++) ...[
                      if (index == 0 ||
                          !_isSameDay(
                            _messages[index - 1].createdAt,
                            _messages[index].createdAt,
                          ))
                        ConversationDayDivider(
                          date: _messages[index].createdAt,
                        ),
                      AssistantBubble(message: _messages[index]),
                    ],
                    if (_sending)
                      AssistantBubble(
                        message: AssistantChatMessage(
                          role: 'assistant',
                          text: 'Thinking through your shelf...',
                          createdAt: DateTime.now(),
                        ),
                      ),
                  ],
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
                    // One line, and a hint short enough not to wrap into a
                    // second one. The old example was 39 characters and split
                    // the bar in two at rest.
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'How does your skin feel?',
                      hintMaxLines: 1,
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

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

/// A light timeline marker keeps a 24-hour conversation scannable without
/// turning the chat into a stack of cards.
class ConversationDayDivider extends StatelessWidget {
  const ConversationDayDivider({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final label = _isSameDay(date, today)
        ? 'TODAY'
        : _isSameDay(date, yesterday)
        ? 'YESTERDAY'
        : '${date.day}/${date.month}/${date.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: ink.withValues(alpha: 0.1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                color: ink.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: ink.withValues(alpha: 0.1))),
        ],
      ),
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
            const SizedBox(height: 8),
            Text(
              TimeOfDay.fromDateTime(message.createdAt).format(context),
              style: TextStyle(
                color: (isUser ? Colors.white : ink).withValues(alpha: 0.58),
                fontSize: 10,
                fontWeight: FontWeight.w700,
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
                    message.quotaLimited
                        ? Icons.hourglass_top_outlined
                        : message.safetyFallback
                        ? Icons.verified_user_outlined
                        : Icons.cloud_off_outlined,
                    size: 13,
                    color: secondary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    message.quotaLimited
                        ? 'Gemini is cooling down - try again shortly'
                        : message.safetyFallback
                        ? 'Safety-reviewed guidance'
                        : 'Offline guidance',
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
