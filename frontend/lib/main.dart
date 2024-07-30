import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:google_cloud/google_cloud.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/aiplatform/v1.dart';



String generateSessionId() {
  // Implementation for generating a random session ID
  // This is a simple example, you might want to use a more robust approach
  final random = Random();
  final characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final sessionId = String.fromCharCodes(Iterable.generate(
      10, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  return sessionId;
}

// Call the function to generate a session ID
String sessionId = generateSessionId();

// Now you can use the 'sessionId' variable in your application
void main() async {
  runApp(MyApp());
  }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT-like Interface',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        hintColor: Colors.blueAccent,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  void _handleSubmitted(String text) {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUser: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    _getBotResponse(text);
  }

  void _getBotResponse(String userMessage) async {
    // This is where we make the call to our Python backend
    final projectId = await computeProjectId();
    print('Current GCP project id: $projectId');
    final authClient = await clientViaApplicationDefaultCredentials(
      scopes: [AiplatformApi.cloudPlatformScope],
    );
    final response = await authClient.post(
      Uri.parse('POST https://us-central1-dialogflow.googleapis.com/v3/projects/cr-genai-demo/locations/us-central1/agents/bdcc42ba-8d04-4e5e-a736-4da87aea2ab1/sessions/$sessionId/message:detectIntent'),  // Replace with your server's address
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'queryInput': {
          'text':{
            'text': userMessage,
          },
          'languageCode': 'en',
          },
          'queryParams':{
            'timeZone': "America/New_York"
          }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String botResponse = data['reply'];
      
      ChatMessage botMessage = ChatMessage(
        text: botResponse,
        isUser: false,
      );
      setState(() {
        _messages.insert(0, botMessage);
      });
    } else {
      print('Failed to get response from backend');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vertex AI Agent Builder App")),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).hintColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text(isUser ? "You" : "Bot")),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isUser ? "You" : "Bot", style: Theme.of(context).textTheme.bodyMedium),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}