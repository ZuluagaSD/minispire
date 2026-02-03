import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Uint8List? initialImageBytes;
  final String? initialPrompt;

  const ChatScreen({
    super.key,
    this.initialImageBytes,
    this.initialPrompt,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _currentResponse = '';
  Uint8List? _pendingImageBytes;
  bool _hasProcessedInitialImage = false;

  @override
  void initState() {
    super.initState();
    // Process initial image if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialImageBytes != null && !_hasProcessedInitialImage) {
        _hasProcessedInitialImage = true;
        _sendMessageWithImage(
          widget.initialPrompt ?? 'How do I paint this?',
          widget.initialImageBytes!,
        );
      }
    });
  }

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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    await _sendMessageWithImage(message, null);
  }

  Future<void> _sendMessageWithImage(String message, Uint8List? imageBytes) async {
    if (message.isEmpty || _isLoading) return;

    // Add user message with optional image
    ref.read(chatHistoryProvider.notifier).update((state) => [
          ...state,
          ChatMessage(content: message, isUser: true, imageBytes: imageBytes),
        ]);
    _scrollToBottom();

    setState(() {
      _isLoading = true;
      _currentResponse = '';
    });

    try {
      final geminiService = ref.read(geminiServiceProvider);

      // Stream the response for better UX
      await for (final chunk in geminiService.streamChat(message, imageBytes: imageBytes)) {
        setState(() {
          _currentResponse += chunk;
        });
        _scrollToBottom();
      }

      // Add AI response to history
      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            ChatMessage(content: _currentResponse, isUser: false),
          ]);

      setState(() {
        _isLoading = false;
        _currentResponse = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ref.read(chatHistoryProvider.notifier).update((state) => [
            ...state,
            ChatMessage(
              content: 'Sorry, I encountered an error: $e',
              isUser: false,
            ),
          ]);
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatHistory = ref.watch(chatHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painting Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: chatHistory.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear chat?'),
                        content: const Text(
                          'This will delete all messages in this conversation.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(chatHistoryProvider.notifier).state = [];
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: chatHistory.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatHistory.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatHistory.length && _isLoading) {
                        // Show streaming response
                        return _ChatBubble(
                          message: _currentResponse.isEmpty
                              ? 'Thinking...'
                              : _currentResponse,
                          isUser: false,
                          isStreaming: true,
                        );
                      }
                      final msg = chatHistory[index];
                      return _ChatBubble(
                        message: msg.content,
                        isUser: msg.isUser,
                        imageBytes: msg.imageBytes,
                      );
                    },
                  ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about painting techniques...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask Your Painting Coach',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Get expert advice on miniature painting techniques, color theory, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'How do I blend colors?',
                  onTap: () {
                    _messageController.text = 'How do I blend colors smoothly on a miniature?';
                    _sendMessage();
                  },
                ),
                _SuggestionChip(
                  label: 'Best primer for metal?',
                  onTap: () {
                    _messageController.text = 'What is the best primer for metal miniatures?';
                    _sendMessage();
                  },
                ),
                _SuggestionChip(
                  label: 'NMM technique tips',
                  onTap: () {
                    _messageController.text = 'Can you explain the NMM (non-metallic metal) technique?';
                    _sendMessage();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isStreaming;
  final Uint8List? imageBytes;

  const _ChatBubble({
    required this.message,
    required this.isUser,
    this.isStreaming = false,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show image if present
            if (imageBytes != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.memory(
                  imageBytes!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
