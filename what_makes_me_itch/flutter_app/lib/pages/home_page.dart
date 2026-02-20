import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'custom_app_bar.dart';
import '../theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<Map<String, String>> messages = [];
  final List<String> savedEntries = []; // TEMP entry storage
  final TextEditingController _controller = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isNewChat = true;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  /// -------- SAVE AS ENTRY --------
  void _saveAsEntry(String entryText) {
    setState(() {
      savedEntries.add(entryText);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Entry saved successfully."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// -------- SEND MESSAGE --------
  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;

    setState(() {
      messages.add({"sender": "user", "text": userMessage});
      messages.add({"sender": "ai", "text": "Typing..."});
    });

    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "message": userMessage,
          "new_chat": _isNewChat,
        }),
      );

      setState(() {
        messages.removeLast();
        messages.add({
          "sender": "ai",
          "text": response.statusCode == 200
              ? jsonDecode(response.body)["response"]
              : "Error: AI failed to respond."
        });
      });
    } catch (_) {
      setState(() {
        messages.removeLast();
        messages.add(
            {"sender": "ai", "text": "Error: Could not connect to server."});
      });
    }

    _isNewChat = false;
  }

  /// -------- VOICE INPUT --------
  void _startListening() async {
    if (await _speech.initialize()) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() => _controller.text = result.recognizedWords);
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  /// -------- UI --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: "Chat with Allergy AI"),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message["sender"] == "user";
                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    /// Message bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message["text"]!,
                        style: TextStyle(
                          color: isUser ? Colors.white : AppColors.navyText,
                        ),
                      ),
                    ),

                    /// Save as Entry (AI only)
                    if (!isUser)
                      TextButton.icon(
                        onPressed: () => _saveAsEntry(message["text"]!),
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text("Save as Entry"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.coral,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          /// Input bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  color: AppColors.darkBlue,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("How to Use"),
                        content: const Text(
                          "Use chat to explore reactions. Save AI responses as entries to log potential allergens.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Enter potential allergen...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: AppColors.teal,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AppColors.coral,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
