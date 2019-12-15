// import 'package:Solon/api/secret.dart';
import 'package:flutter/material.dart';
// import 'package:Solon/app_localizations.dart';
import 'package:Solon/api/api_connect.dart';
import 'package:Solon/api/message.dart';
import 'package:Solon/loader.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Message>(
          future: APIConnect.connectRoot(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text("${snapshot.data.message}");
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return Loader();
          }
        ),
      ),
    );
  }
}
