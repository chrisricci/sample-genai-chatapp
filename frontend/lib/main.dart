import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:google_cloud/google_cloud.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/aiplatform/v1.dart';

import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/web_only.dart';

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'src/sign_in_button.dart';

/// The scopes required by this application.
// #docregion Initialize
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/cloud-platform',
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  clientId: '816770041921-ui63do9i696et53m7j96557f22qubd7b.apps.googleusercontent.com',
  scopes: scopes,
);
// #enddocregion Initialize

void main() {
  runApp(
    const MaterialApp(
      title: 'Google Sign In',
      home: SignInDemo(),
    ),
  );
}

/// The SignInDemo app.
class SignInDemo extends StatefulWidget {
  ///
  const SignInDemo({super.key});

  @override
  State createState() => _SignInDemoState();
}

class _SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false; // has granted permissions?
  String _contactText = '';

  @override
  void initState() {
    super.initState();

    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      bool isAuthorized = account != null;
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.requestScopes(scopes);
      }

      setState(() {
        _currentUser = account;
        _isAuthorized = isAuthorized;
      });
    });

    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      // The user is Authenticated
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: GoogleUserCircleAvatar(
                identity: user,
              ),
              title: Text(user.displayName ?? ''),
              subtitle: Text(user.email),
            ),
          ),
          Expanded(
            child: ChatScreen(user: user),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _handleSignOut,
              child: const Text('SIGN OUT'),
            ),
          ),
        ],
      );
    } else {
      // The user is NOT Authenticated
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text('You are not currently signed in.'),
          buildSignInButton(
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign In'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(),
      ),
    );
  }
}

String generateSessionId() {
  // Implementation for generating a random session ID
  // This is a simple example, you might want to use a more robust approach
  final random = Random();
  final characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final sessionId = String.fromCharCodes(Iterable.generate(
      10, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  return sessionId;
}

//class MyChatApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return ChatScreen();
//  }
//}
//class MyChatApp extends StatelessWidget {
//  @override
//  // Call the function to generate a session ID
//  Widget build(BuildContext context) {
//    return MaterialApp(
////      title: 'ChatGPT-like Interface',
//      theme: ThemeData(
//        primarySwatch: Colors.blue,
//        hintColor: Colors.blueAccent,
//      ),
//      home: ChatScreen(),
//    );
//  }
//}


class ChatScreen extends StatefulWidget {
  final GoogleSignInAccount user;

  ChatScreen({required this.user});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

//class ChatScreen extends StatefulWidget {
//  @override
//  _ChatScreenState createState() => _ChatScreenState();
//}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      _sessionId = generateSessionId();
    });
    
  }

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
    final authHeaders = await _getAuthHeaders();

    // Use the credential to create an HTTP client
    print('Session ID initialized: $_sessionId');
    final response = await http.post(
      Uri.parse('https://us-central1-dialogflow.googleapis.com/v3/projects/cr-genai-demo/locations/us-central1/agents/bdcc42ba-8d04-4e5e-a736-4da87aea2ab1/sessions/$_sessionId:detectIntent'),  // Replace with your server's address
      headers: <String, String>{
        ...authHeaders,
        'x-goog-user-project': 'cr-genai-demo',
        'Content-Type': 'application/json; charset=UTF-8',
        //'Access-Control-Allow-Origin': 'http://localhost:61478'
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
        String botResponse = data['queryResult']['responseMessages'][0]['text']['text'][0];
        
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
    Future<Map<String, String>> _getAuthHeaders() async {
      final GoogleSignInAuthentication? auth = await widget.user.authentication;
      final String? token = auth?.accessToken;
      print('Current Access Token: $token');
      return {'Authorization': 'Bearer $token'};
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(title: Text("Vertex AI Agent Builder App")),
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