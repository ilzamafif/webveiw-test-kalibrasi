import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thermocouple',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://iot.wyasaaplikasi.com/', // Ganti dengan URL awal Anda
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
        gestureNavigationEnabled: true,
        onPageFinished: (String url) {
          // Menjalankan JavaScript untuk memeriksa local storage
          _controller.future.then((webViewController) {
          });
        },
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith("https://iot.wyasaaplikasi.com/")) {
            return NavigationDecision.navigate;
          } else if (request.url.startsWith("myapp://redirect")) {
            // Custom URL scheme to handle redirect back to the app
            handleCustomUrlScheme(request.url);
            return NavigationDecision.prevent;
          } else {
            _launchURL(request.url);
            return NavigationDecision.prevent;
          }
        },
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  void handleCustomUrlScheme(String url) {
    // Extract data from the URL if needed
    Uri uri = Uri.parse(url);
    String? token = uri.queryParameters['access_token'];

    // Handle the redirect and navigate to a different screen if needed
    if (token != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SuccessPage(token: token)),
      );
    } else {
      // Handle the case where the token is null
      print('No access token found in URL');
    }
  }

  void playAlarm() async {
    await audioPlayer.play(AssetSource('assets/audio/alarm.mp3'));
  }
}

class SuccessPage extends StatelessWidget {
  final String token;

  SuccessPage({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Success"),
      ),
      body: Center(
        child: Text("Data successfully uploaded! Token: $token"),
      ),
    );
  }
}
