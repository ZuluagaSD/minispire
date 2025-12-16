import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

/// Result from image generation containing image bytes and description
class InspirationResult {
  final Uint8List imageBytes;
  final String description;
  final DateTime createdAt;

  InspirationResult({
    required this.imageBytes,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Service for interacting with Gemini AI models via Firebase AI Logic
class GeminiService {
  GenerativeModel? _flashModel;
  GenerativeModel? _proModel;
  GenerativeModel? _chatModel;

  /// Initialize the Gemini models
  void initialize() {
    // Nano Banana - Fast model for quick iterations (up to 1024px)
    _flashModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-image',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text, ResponseModalities.image],
      ),
    );

    // Nano Banana Pro - High quality model (up to 4K)
    _proModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-pro-image-preview',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text, ResponseModalities.image],
      ),
    );

    // Text-only model for chat
    _chatModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.0-flash',
    );
  }

  /// Generate inspiration image from a text prompt
  ///
  /// [prompt] - Description of the miniature paint scheme
  /// [highQuality] - Use Nano Banana Pro for 4K output (slower)
  /// [referenceImage] - Optional reference image for style transfer
  Future<InspirationResult> generateInspiration(
    String prompt, {
    bool highQuality = false,
    Uint8List? referenceImage,
  }) async {
    final model = highQuality ? _proModel : _flashModel;
    if (model == null) {
      throw StateError('GeminiService not initialized. Call initialize() first.');
    }

    // Build the prompt with miniature painting context
    final enhancedPrompt = _buildMiniaturePrompt(prompt);

    // Create content parts
    final List<Part> parts = [];

    if (referenceImage != null) {
      parts.add(InlineDataPart('image/jpeg', referenceImage));
      parts.add(TextPart('Using the style from the reference image above, $enhancedPrompt'));
    } else {
      parts.add(TextPart(enhancedPrompt));
    }

    final response = await model.generateContent([Content.multi(parts)]);

    // Extract image and text from response
    if (response.inlineDataParts.isEmpty) {
      throw Exception('No image was generated. Please try a different prompt.');
    }

    final imageBytes = response.inlineDataParts.first.bytes;
    final description = response.text ?? prompt;

    return InspirationResult(
      imageBytes: imageBytes,
      description: description,
    );
  }

  /// Chat with the AI painting coach
  Future<String> chat(String message, {List<Content>? history}) async {
    if (_chatModel == null) {
      throw StateError('GeminiService not initialized. Call initialize() first.');
    }

    final chat = _chatModel!.startChat(
      history: history ?? [],
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
      ),
    );

    // Add context for miniature painting advice
    final contextualMessage = '''
You are an expert miniature painting coach helping hobbyists improve their skills.
You have deep knowledge of:
- Paint brands (Citadel, Vallejo, Army Painter, Scale75, etc.)
- Painting techniques (wet blending, layering, drybrushing, glazing, etc.)
- Color theory and composition
- Miniature preparation and priming
- Weathering and basing techniques

User question: $message
''';

    final response = await chat.sendMessage(Content.text(contextualMessage));
    return response.text ?? 'I apologize, but I could not generate a response.';
  }

  /// Stream chat responses for better UX
  Stream<String> streamChat(String message, {List<Content>? history}) async* {
    if (_chatModel == null) {
      throw StateError('GeminiService not initialized. Call initialize() first.');
    }

    final chat = _chatModel!.startChat(history: history ?? []);

    final contextualMessage = '''
You are an expert miniature painting coach. Help the user with their question.
User: $message
''';

    final stream = chat.sendMessageStream(Content.text(contextualMessage));

    await for (final chunk in stream) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }

  /// Analyze an image and extract color palette
  Future<List<String>> extractColors(Uint8List imageBytes) async {
    if (_chatModel == null) {
      throw StateError('GeminiService not initialized. Call initialize() first.');
    }

    final prompt = '''
Analyze this miniature painting image and extract the main colors used.
For each color, provide:
1. The color name
2. The closest Citadel paint match
3. The closest Vallejo paint match

Format your response as a simple list, one color per line.
Example:
- Dark Blue: Citadel Kantor Blue / Vallejo Dark Prussian Blue
- Gold: Citadel Retributor Armour / Vallejo Liquid Gold
''';

    final response = await _chatModel!.generateContent([
      Content.multi([
        InlineDataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ])
    ]);

    // Parse the response into a list of colors
    final text = response.text ?? '';
    return text
        .split('\n')
        .where((line) => line.trim().startsWith('-'))
        .map((line) => line.trim().substring(1).trim())
        .toList();
  }

  /// Build an enhanced prompt for miniature painting context
  String _buildMiniaturePrompt(String userPrompt) {
    return '''
Generate a high-quality reference image for miniature painting.
Style: Detailed miniature wargaming model, tabletop quality
Subject: $userPrompt
Requirements:
- Clear color scheme visible
- Good lighting to show paint details
- Painterly style suitable for miniature reference
- Include interesting details like weathering or battle damage if appropriate
''';
  }
}
