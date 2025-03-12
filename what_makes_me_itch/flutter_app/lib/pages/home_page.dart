import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'custom_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String userMessage = _controller.text;

      setState(() {
        messages.add({"sender": "user", "text": userMessage});
        messages.add({"sender": "ai", "text": "Typing..."});
      });

      _controller.clear();

      try {
        var response = await http.post(
          Uri.parse("http://127.0.0.1:5000/chat"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": "1",
            "message": userMessage,
            "new_chat": messages.isEmpty // Start a new session if chat is empty
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          setState(() {
            messages.removeLast(); // Remove "Typing..."
            messages.add({"sender": "ai", "text": data["response"]});
          });
        } else {
          setState(() {
            messages.removeLast();
            messages
                .add({"sender": "ai", "text": "Error: AI failed to respond."});
          });
        }
      } catch (e) {
        setState(() {
          messages.removeLast();
          messages.add(
              {"sender": "ai", "text": "Error: Could not connect to server."});
        });
      }
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _editMessage(int index) {
    TextEditingController editController =
        TextEditingController(text: messages[index]["text"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Message"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              String editedText = editController.text;

              if (editedText.isNotEmpty) {
                setState(() {
                  // Remove the original user message
                  messages.removeAt(index);

                  // Remove the AI response after the user message (if exists)
                  if (index < messages.length &&
                      messages[index]["sender"] == "ai") {
                    messages.removeAt(index);
                  }

                  // Add the edited user message
                  messages.add({"sender": "user", "text": editedText});
                });

                // Send the edited message to the backend
                _sendEditedMessage(editedText);
              }

              Navigator.pop(context);
            },
            child: Text("Resend"),
          ),
        ],
      ),
    );
  }

  void _sendEditedMessage(String message) async {
    try {
      var response = await http.post(
        Uri.parse(
            "http://127.0.0.1:5000/chat"), // Update with actual Flask API URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          messages.add({"sender": "ai", "text": data["response"]});
        });
      } else {
        setState(() {
          messages.add(
              {"sender": "ai", "text": "Error: Unable to get a response."});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "sender": "ai",
          "text": "Error: Unable to connect to the server."
        });
      });
    }
  }

  void _undoMessage(int index) {
    setState(() {
      if (index < messages.length && messages[index]["sender"] == "user") {
        messages.removeAt(index);
        if (messages.isNotEmpty && messages.last["sender"] == "ai") {
          messages.removeLast();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Chat with Allergy AI"),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message["sender"] == "user";
                return Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message["text"]!,
                        style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (isUser) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                Icon(Icons.edit, size: 18, color: Colors.grey),
                            onPressed: () => _editMessage(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.undo, size: 18, color: Colors.red),
                            onPressed: () => _undoMessage(index),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.help_outline, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("How to Use"),
                        content: Text(
                            "Enter allergens manually or use voice input. Your data is analyzed for patterns but is not a medical diagnosis."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("OK"),
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
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.blue),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
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
