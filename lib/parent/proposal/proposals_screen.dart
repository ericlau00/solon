import 'dart:convert';

import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

import './proposal.dart';
import './addproposal_screen.dart';
import '../../loader.dart';

class ProposalsScreen extends StatefulWidget {
  @override
  _ProposalsScreenState createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends State<ProposalsScreen> {
  //List<Widget> _proposalsList = [];
  final db = Firestore.instance;
  final translator = GoogleTranslator();
  String _languageCode;

  void _addProposal(
    String proposalTitle,
    String proposalSubtitle,
    DateTime dateTime,
    TimeOfDay timeOfDay,
  ) {
    db.collection('proposals').add(
      {
        'proposalTitle': proposalTitle,
        'proposalSubtitle': proposalSubtitle,
        'timeOfDay': timeOfDay.toString(),
        'dateTime': dateTime.toString(),
      },
    );
  }

  Future<String> translateProposalTitleToNativeLanguage(DocumentSnapshot doc) async {
    print('hey1');
    Future proposalTitle = translator.translate(doc.data['proposalTitle'], to: _languageCode);
    print('hey2');
    return proposalTitle;
  }

  Widget buildProposal(doc) {
    return FutureBuilder(
      future: translateProposalTitleToNativeLanguage(doc),
      builder: (BuildContext context, AsyncSnapshot<String> proposalTitle) {
        print(proposalTitle.data);
        return Proposal(
          proposalTitle.hasData ? proposalTitle.data : '',
          doc.data['proposalSubtitle'],
          DateTime.parse(doc.data['dateTime']),
          TimeOfDay(
            hour: int.parse(doc.data['timeOfDay'].substring(10, 12)),
            minute: int.parse(doc.data['timeOfDay'].substring(13, 15))),
          0,
          0,
          doc,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: db.collection('proposals').orderBy('dateTime', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Scaffold(
                body: Center(
                  child: Loader(),
                ),
              );
            default:
              return Scaffold(
                body: Center(
                  child: ListView(
                    padding: EdgeInsets.all(8),
                    children: <Widget>[
                      Column(
                        children: snapshot.data.documents
                            .map((doc) => buildProposal(doc))
                            .toList(),
                      )
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  heroTag: 'unq1',
                  child: Icon(Icons.add),
                  onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddProposalScreen(_addProposal)),
                    )
                  },
                ),
              );
          }
        });
  }
}
