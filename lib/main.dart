import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();
  static const _clientId =
      '812976116770-7q6pr2ebj481dk1t5necb64d510n7ot3.apps.googleusercontent.com';
  static const _scopes = ['https://www.googleapis.com/auth/drive.file'];
  late AuthClient _client;

  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: <Widget>[
      Expanded(
        child: InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(url: WebUri("iot.wyasaaplikasi.com")),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onPermissionRequest: (controller, request) async {
            final resources = <PermissionResourceType>[];
            if (request.resources.contains(PermissionResourceType.CAMERA)) {
              final cameraStatus = await Permission.camera.request();
              if (!cameraStatus.isDenied) {
                resources.add(PermissionResourceType.CAMERA);
              }
            }
            if (request.resources.contains(PermissionResourceType.MICROPHONE)) {
              final microphoneStatus = await Permission.microphone.request();
              if (!microphoneStatus.isDenied) {
                resources.add(PermissionResourceType.MICROPHONE);
              }
            }
            // only for iOS and macOS
            if (request.resources
                .contains(PermissionResourceType.CAMERA_AND_MICROPHONE)) {
              final cameraStatus = await Permission.camera.request();
              final microphoneStatus = await Permission.microphone.request();
              if (!cameraStatus.isDenied && !microphoneStatus.isDenied) {
                resources.add(PermissionResourceType.CAMERA_AND_MICROPHONE);
              }
            }

            return PermissionResponse(
                resources: resources,
                action: resources.isEmpty
                    ? PermissionResponseAction.DENY
                    : PermissionResponseAction.GRANT);
          },
        ),
      ),
      ElevatedButton(
        onPressed: _handleAuthClick,
        child: Text('Show Flutter homepage'),
      ),
    ]));
  }

  Future<void> _handleAuthClick() async {
    final auth = await clientViaUserConsent(
        ClientId(_clientId, null), _scopes, _launchUrl);
    setState(() {
      _client = auth;
    });
    await _uploadFile();
  }

  Future<void> _uploadFile() async {
    final driveApi = drive.DriveApi(_client);
    final file = drive.File();
    file.name = 'data.txt';
    file.mimeType = 'text/plain';

    final fileContent = 'Hello, world!';
    final media = drive.Media(
      Stream.value(fileContent.codeUnits),
      fileContent.length,
    );

    final response = await driveApi.files.create(file, uploadMedia: media);
    print('File ID: ${response.id}');
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
