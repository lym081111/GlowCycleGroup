/// One turn in the Glow Assistant conversation.
class AssistantChatMessage {
  const AssistantChatMessage({
    required this.role,
    required this.text,
    this.safetyNote,
    this.fromFallback = false,
  });

  /// Either `user` or `assistant`.
  final String role;

  /// The turn's content. Only this is replayed as conversation history, so
  /// the repeated safety disclaimer never fills the context window.
  final String text;

  /// Assistant turns only: the disclaimer rendered beneath [text].
  final String? safetyNote;

  /// Assistant turns only: true when the offline rule engine answered.
  final bool fromFallback;
}
