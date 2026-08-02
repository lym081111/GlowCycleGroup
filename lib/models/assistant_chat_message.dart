/// One turn in the Glow Assistant conversation.
class AssistantChatMessage {
  const AssistantChatMessage({required this.role, required this.text});

  /// Either `user` or `assistant`.
  final String role;
  final String text;
}
