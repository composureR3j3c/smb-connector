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
    return const MaterialApp(
       debugShowCheckedModeBanner: false,
      home: SmbTestPage(),
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
  bool connected = false;
  late DirectoryPoller poller;

  String status = "Disconnected";

  @override
  void initState() {
    super.initState();

    connect();

    poller = DirectoryPoller(
      directory: "/storage/emulated/0/Download",
    );

    poller.start((file) async {
      print("==================================");
      print("NEW FILE DETECTED");
      print(file.path);
      print("==================================");

      await Future.delayed(const Duration(seconds: 2));

      await uploadFile(file);
    });
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  Future<void> connect() async {
    if (connected) return;

    try {
      print("Connecting...");

      smb = await SmbConnect.connectAuth(
        host: "10.5.32.70",
        domain: "",
        username: "YOUR_WINDOWS_USERNAME",
        password: "YOUR_WINDOWS_PASSWORD",
      );

      connected = true;

      print("Connected.");

      final shares = await smb!.listShares();

      print("Available Shares:");

      for (final s in shares) {
        print(s.path);
      }

      setState(() {
        status = "Connected";
      });
    } catch (e, s) {
      print(e);
      print(s);

      setState(() {
        status = "Connection Failed";
      });
    }
  }

  Future<void> uploadFile(File localFile) async {
    try {
      print("========== UPLOAD ==========");

      if (!connected || smb == null) {
        print("Not connected.");
        return;
      }

      print("Local File : ${localFile.path}");

      bool exists = await localFile.exists();

      print("Exists : $exists");

      if (!exists) {
        return;
      }

      print("Size : ${await localFile.length()} bytes");

      final fileName = localFile.uri.pathSegments.last;

      print("Remote Name : $fileName");

      print("Creating remote file...");

      final remoteFile =
          await smb!.createFile("/Shared/$fileName");

      print("Remote file created.");

      print("Opening writer...");

      final writer = await smb!.openWrite(remoteFile);

      print("Writing...");

      await writer.addStream(localFile.openRead());

      print("Flush...");

      await writer.flush();

      print("Close...");

      await writer.close();

      print("UPLOAD SUCCESS");

      setState(() {
        status = "Uploaded : $fileName";
      });
    } catch (e, s) {
      print("UPLOAD FAILED");
      print(e);
      print(s);

      setState(() {
        status = "Upload Failed";
      });
    }
  }

  Future<void> createTestFile() async {
    final file = File("/storage/emulated/0/Download/test.txt");

    await file.writeAsString(
      "Hello from Flutter\n${DateTime.now()}",
    );

    print("Created : ${file.path}");

    print(await file.exists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMB Upload Test"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: connect,
              child: const Text("Connect"),
            ),

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