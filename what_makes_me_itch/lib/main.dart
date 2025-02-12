import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


void main() {
  runApp(
      DevicePreview(
          builder: (context) =>
        MyApp()
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'What Makes Me Itch',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0x00575757),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.green,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)),
          bodyMedium: TextStyle(fontSize: 16, color: const Color.fromARGB(221, 255, 255, 255)),
        ),
      ),
      home: LoginPage(),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10);
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Track the selected tab

  final List<Widget> _pages = [
    HomePage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Prevents shifting effect
        backgroundColor: Colors.blue, // Background color
        selectedItemColor: Colors.white, // Selected icon/text color
        unselectedItemColor: Colors.grey[300], // Unselected icon/text color
        elevation: 10, // Adds shadow effect
        iconSize: 30, // Adjust icon size
        selectedFontSize: 16, // Adjust font size for selected tab
        unselectedFontSize: 14, // Adjust font size for unselected tab
        onTap: _onItemTapped,
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "What makes me itch?"),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Keeping track of allergies for you!", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[200]),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[200]),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
                },
                child: Text("Login"),
              ),
              SizedBox(height: 40),
              TextButton(
                onPressed: () {},
                child: Text("Create an Account", style: TextStyle(color: Colors.blue, fontSize: 16)),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '"What Makes Me Itch" is not liable. Please see a doctor for more accurate results.',
                  style: TextStyle(color: const Color.fromARGB(255, 196, 196, 196), fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({"sender": "user", "text": _controller.text});
        messages.add({"sender": "ai", "text": "I'm analyzing this potential allergen... Can you describe your symptoms?"});
      });
      _controller.clear();
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
    TextEditingController editController = TextEditingController(text: messages[index]["text"]);
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
              setState(() {
                messages[index]["text"] = editController.text;
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
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
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message["text"]!,
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (isUser) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: Colors.grey),
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
                        content: Text("Enter allergens manually or use voice input. Your data is analyzed for patterns but is not a medical diagnosis."),
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
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.blue),
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> allergens = [
    {"severity": "High Severity", "items": ["Peanuts", "Shellfish"]},
    {"severity": "Medium Severity", "items": ["Dust Mites", "Dairy"]},
    {"severity": "Low Severity", "items": ["Pollens", "Pet Dander"]},
  ];

  void _editPersonalInfo() {
    // Implement edit functionality here
  }

  void _deleteAllergen(String severity, String allergen) {
    setState(() {
      for (var group in allergens) {
        if (group["severity"] == severity) {
          group["items"].remove(allergen);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Profile"),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Personal Information", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 10),
            Center(
              child: Container(
                width: 350,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("John Doe", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Age: 25", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 5),
                    Text("Email: johndoe@example.com", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _editPersonalInfo,
                      child: Text("Edit Information"),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Potential Allergens", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: allergens.length,
                        itemBuilder: (context, index) {
                          final allergenGroup = allergens[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(allergenGroup["severity"],
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                              Column(
                                children: List.generate(
                                  allergenGroup["items"].length,
                                  (i) => Card(
                                    child: ListTile(
                                      title: Text(allergenGroup["items"][i]),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteAllergen(allergenGroup["severity"], allergenGroup["items"][i]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {}, // Placeholder for future allergen editing functionality
                      child: Text("Edit Allergens"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



