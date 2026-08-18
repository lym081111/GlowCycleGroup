/// One turn in the Glow Assistant conversation.
class AssistantChatMessage {
  const AssistantChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
    this.safetyNote,
    this.fromFallback = false,
    this.safetyFallback = false,
    this.quotaLimited = false,
  });

  /// Either `user` or `assistant`.
  final String role;

  /// The turn's content. Only this is replayed as conversation history, so
  /// the repeated safety disclaimer never fills the context window.
  final String text;

  /// Local display time for the 24-hour conversation timeline.
  final DateTime createdAt;

  /// Assistant turns only: the disclaimer rendered beneath [text].
  final String? safetyNote;

  /// Assistant turns only: true when the offline rule engine answered.
  final bool fromFallback;

  /// Whether Gemini was available but its answer needed a local safety retry.
  final bool safetyFallback;

  /// True when Firebase AI surfaced a short-term Gemini quota limit.
  final bool quotaLimited;
}
