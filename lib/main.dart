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

  final Set<String> uploadedFiles = {};

  @override
  void initState() {
    super.initState();

    connect();

    poller = DirectoryPoller(
      directory: "/storage/emulated/0/Download",
    );


    poller.start((file) async {

      if (uploadedFiles.contains(file.path)) {
        return;
      }

      uploadedFiles.add(file.path);

      print("New file detected: ${file.path}");

      // wait until file writing completes
      await Future.delayed(
        const Duration(seconds: 2),
      );

      await uploadFile(file);

    });
  }


  @override
  void dispose() {

    poller.stop();

    super.dispose();

  }



  Future<void> connect() async {

    try {

      print("Connecting SMB...");


      smb = await SmbConnect.connectAuth(

        host: "10.5.32.70",

        domain: "",

        username: "YOUR_WINDOWS_USERNAME",

        password: "YOUR_WINDOWS_PASSWORD",

      );


      print("SMB connected");


      setState(() {

        status = "Connected";

      });


    } catch(e) {


      print("SMB connection failed: $e");


      smb = null;


      setState(() {

        status = "Disconnected";

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


    } catch(e) {


      print("Connection lost: $e");


      smb = null;


      return false;


    }

  }





  Future<void> uploadFile(File localFile) async {


    try {


      bool alive = await isConnected();



      if (!alive) {


        print("SMB disconnected. Reconnecting...");


        await connect();


        alive = await isConnected();



        if (!alive) {


          print("Reconnect failed");


          return;


        }

      }



      final fileName =
          localFile.uri.pathSegments.last;



      print("Uploading $fileName");



      final remoteFile =
          await smb!.createFile(

            "/Shared/$fileName",

          );



      final writer =
          await smb!.openWrite(remoteFile);



      await writer.addStream(
        localFile.openRead(),
      );



      await writer.flush();


      await writer.close();



      print("Upload completed: $fileName");



      setState(() {

        status = "Uploaded: $fileName";

      });



    } catch(e, stack) {


      print("Upload error: $e");

      print(stack);



      smb = null;



      print("Retrying after reconnect...");



      await Future.delayed(
        const Duration(seconds: 3),
      );



      await connect();



      if (smb != null) {

        await uploadFile(localFile);

      }


    }


  }






  Future<void> createTestFile() async {


    final file =
        File("/storage/emulated/0/Download/test.txt");



    await file.writeAsString(

      "Hello from Flutter\n"
      "${DateTime.now()}",

    );


    print("Created test file");

  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text("SMB Auto Upload"),

      ),



      body: Center(


        child: Column(


          mainAxisAlignment:
              MainAxisAlignment.center,


          children: [



            Text(status),



            const SizedBox(height: 20),



            ElevatedButton(

              onPressed: connect,

              child:
                  const Text("Connect SMB"),

            ),




            ElevatedButton(

              onPressed: createTestFile,

              child:
                  const Text("Create Test File"),

            ),



          ],

        ),


      ),


    );


  }

}