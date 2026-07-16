import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smb_connect/smb_connect.dart';
import 'package:smb_connect_java/util/DirectoryPoller.dart';
// import 'package:file_selector/file_selector.dart';
// import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const SmbTestPage());
  }
}

class SmbTestPage extends StatefulWidget {
  const SmbTestPage({super.key});

  @override
  State<SmbTestPage> createState() => _SmbTestPageState();
}

class _SmbTestPageState extends State<SmbTestPage> {
  SmbConnect? smb;

  String status = "Disconnected";

  late DirectoryPoller poller;

  @override
  void initState() {
    super.initState();

    poller = DirectoryPoller(directory: "/storage/emulated/0/Download");
    

    poller.start((file) async {
      print("New file: ${file.path}");
    });
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  Future<void> connect() async {
    try {
      smb = await SmbConnect.connectAuth(
        host: "10.5.32.70",

        domain: "",

        username: "YOUR_WINDOWS_USERNAME",

        password: "YOUR_WINDOWS_PASSWORD",
      );

      setState(() {
        status = "Connected";
      });

      // var shares = await smb!.listShares();
      SmbFile folder = await smb!.file("/Shared");
      List<SmbFile> files = await smb!.listFiles(folder);
      // final XFile? file = await openFile();

      // if (file != null) {
      //   File uploadFile = File(file.path);
      // }

      SmbFile remoteFile = await smb!.createFile("/Shared/test.txt");

      print(files.map((e) => e.path).join("\n"));
      if (files.isNotEmpty) {
        SmbFile remoteFile = await smb!.createFile(
          "/Shared/test${DateTime.now().microsecondsSinceEpoch}.txt",
        );

        setState(() {
          status = "Written File: ${remoteFile}";
        });
      }
    } catch (e) {
      print("Error: $e");
      // setState(() {
      //   status = "Error: $e";
      // });
    }
  }

  Future<void> createAndUpload() async {
    if (smb == null) {
      return;
    }

    // Create local test file

    final localFile = File("/data/data/com.example.smb_demo/test.txt");

    await localFile.writeAsString(
      "Hello from Flutter SMB test\n"
      "Time: ${DateTime.now()}",
    );

    // Create remote file
    //
    // Windows:
    // \\10.5.32.70\Shared\test.txt
    //
    // SMB path:
    // /Shared/test.txt

    SmbFile remoteFile = await smb!.createFile("/Shared/test.txt");

    IOSink writer = await smb!.openWrite(remoteFile);

    await writer.addStream(localFile.openRead());

    await writer.flush();

    await writer.close();

    setState(() {
      status = "File uploaded";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SMB Test")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(status),

            ElevatedButton(onPressed: connect, child: const Text("Connect")),

            ElevatedButton(
              onPressed: createAndUpload,

              child: const Text("Create TXT + Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
