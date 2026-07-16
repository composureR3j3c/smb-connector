import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smb_connect/smb_connect.dart';
import 'package:smb_connect_java/util/DirectoryPoller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003A70), // BOA Blue
          primary: const Color(0xFF003A70),
          secondary: const Color(0xFFF2B705), // Gold
          surface: Colors.white,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003A70),
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003A70),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),

        // Text fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          labelStyle: const TextStyle(color: Color(0xFF003A70)),

          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFF2B705), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),

          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),

          prefixIconColor: Color(0xFF003A70),
        ),

        // Cursor color
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF003A70),
          selectionColor: Color(0x33F2B705),
          selectionHandleColor: Color(0xFFF2B705),
        ),

        // Text
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1F2937)),
          bodyMedium: TextStyle(color: Color(0xFF374151)),
        ),

        // Cards
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      home: const SmbTestPage(),
    );
  }
}

class SmbTestPage extends StatefulWidget {
  const SmbTestPage({super.key});

  @override
  State<SmbTestPage> createState() => _SmbTestPageState();
}

class _SmbTestPageState extends State<SmbTestPage> {
  SmbConnect? smb;

  late DirectoryPoller poller;

  String status = "Disconnected";

  // SMB settings
  final hostController = TextEditingController(text: "10.5.32.70");

  final shareController = TextEditingController(text: "Shared");

  final usernameController = TextEditingController(text: "");

  final passwordController = TextEditingController(text: "");
  final directoryController = TextEditingController(
    text: "/storage/emulated/0/DCIM/CamScanner",
  );

  final Set<String> uploadedFiles = {};

  @override
  void initState() {
    super.initState();

    poller = DirectoryPoller(directory: "/storage/emulated/0/Download");
    poller = DirectoryPoller(directory: directoryController.text.trim());

    poller.start((file) async {
      if (uploadedFiles.contains(file.path)) {
        return;
      }

      uploadedFiles.add(file.path);

      print("New file: ${file.path}");

      await Future.delayed(const Duration(seconds: 2));

      await uploadFile(file);
    });
  }

  @override
  void dispose() {
    poller.stop();

    hostController.dispose();
    shareController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    directoryController.dispose();

    super.dispose();
  }

  Future<void> connect() async {
    try {
      print("Connecting...");

      smb = await SmbConnect.connectAuth(
        host: hostController.text.trim(),

        domain: "",

        username: usernameController.text.trim(),

        password: passwordController.text,
      );

      print("Connected");

      setState(() {
        status = "Connected";
      });
    } catch (e) {
      print("Connection failed: $e");

      smb = null;

      setState(() {
        status = "Connection Failed";
      });
    }
  }

  Future<bool> isConnected() async {
    try {
      if (smb == null) {
        return false;
      }

      await smb!.listShares();

      return true;
    } catch (e) {
      smb = null;

      return false;
    }
  }

  Future<void> uploadFile(File file) async {
    try {
      if (!await isConnected()) {
        print("Reconnecting...");

        await connect();

        if (smb == null) {
          return;
        }
      }

      final fileName = file.uri.pathSegments.last;

      final remotePath = "/${shareController.text.trim()}/$fileName";

      print("Uploading to $remotePath");

      final remoteFile = await smb!.createFile(remotePath);

      final writer = await smb!.openWrite(remoteFile);

      await writer.addStream(file.openRead());

      await writer.flush();

      await writer.close();

      setState(() {
        status = "Uploaded: $fileName";
      });

      print("Upload completed");
    } catch (e) {
      print("Upload error: $e");

      smb = null;
    }
  }

  Future<void> createTestFile() async {
    final file = File("/storage/emulated/0/Download/test.txt");

    await file.writeAsString(
      "Flutter SMB Upload\n"
      "${DateTime.now()}",
    );

    print("Test file created");
  }

  Widget input(
    String label,
    TextEditingController controller, {
    bool password = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(5),

      child: TextField(
        controller: controller,

        obscureText: password,

        decoration: InputDecoration(
          border: const OutlineInputBorder(),

          labelText: label,
        ),
      ),
    );
  }

  Color getStatusBackgroundColor() {
    if (status.contains("Connected")) {
      return Colors.green.shade300;
    }

    if (status.contains("Uploaded")) {
      return Colors.blue.shade300;
    }

    if (status.contains("Failed") || status.contains("Error")) {
      return Colors.red.shade300;
    }

    if (status.contains("Connecting")) {
      return Colors.orange.shade300;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text("SMB Auto Upload")
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: getStatusBackgroundColor(),

                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            input("Host", hostController),

            input("Share Folder", shareController),

            input("Username", usernameController),

            input("Password", passwordController, password: true),
            input("Listening Directory", directoryController),

            const SizedBox(height: 10),

            ElevatedButton(onPressed: connect, child: const Text("Connect")),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: createTestFile,

              child: const Text("Create Test File"),
            ),
          ],
        ),
      ),
    );
  }
}
