import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Solon/models/message.dart';
import 'package:Solon/screens/forum/comment.dart';

class APIConnect {
  static final String url = "https://api.solonedu.com";

  static final Future<Map<String, String>> headers = getHeaders();

  static Future<Map<String, String>> getHeaders() async {
    return {
      HttpHeaders.authorizationHeader:
          await rootBundle.loadString('assets/secret'),
      HttpHeaders.contentTypeHeader: "application/json"
    };
  }

  static Stream<List<Comment>> commentListView(int fid) async* {
    yield await connectComments(
      fid: fid,
    );
  }

  static Map<String, String> languages = {
    'English': 'en',
    'Chinese (Simplified)': 'zhcn',
    'Chinese (Traditional)': 'zhtw',
    'Bengali': 'bn',
    'Korean': 'ko',
    'Russian': 'ru',
    'Japanese': 'ja',
    'Ukrainian': 'uk',
  };

  static Map<String, String> langCodeToLang = {
    'en': 'English',
    'zh': 'Chinese (Simplified)',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'bn': 'Bengali',
    'ko': 'Korean',
    'ru': 'Russian',
    'ja': 'Japanese',
    'uk': 'Ukrainian',
  };

  static Future<Message> connectRoot() async {
    final response = await http.get(url);
    int status = response.statusCode;
    return status == 200
        ? Message.fromJson(json.decode(response.body)['message'])
        : throw Exception('Message for root not found.');
  }

  static Future<Message> addProposal(
    String title,
    String description,
    DateTime startTime,
    DateTime endTime,
    int uid,
  ) async {
    final response = await http.post(
      "$url/proposals",
      body: json.encode({
        'title': title,
        'description': description,
        'starttime': startTime.toIso8601String(),
        'endtime': endTime.toIso8601String(),
        'uid': uid,
      }),
      headers: await headers,
    );
    int status = response.statusCode;
    return status == 201
        ? Message.fromJson(json.decode(response.body)['message'])
        : throw Exception('Message field in proposal object not found.');
  }

  static Future<Map<String, dynamic>> registerUser(
    String lang,
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final response = await http.post(
      "$url/users/register",
      body: json.encode({
        'lang': languages[lang],
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'password': password,
      }),
      headers: await headers,
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final http.Response response = await http.post(
        "$url/users/login",
        body: json.encode({'email': email, 'password': password}),
        headers: await headers,
      );

      if (json.decode(response.body)['message'] == 'Error') {
        return json.decode(response.body);
      }

      final userUid = json.decode(response.body)["uid"];

      final http.Response userDataResponse = await http.get(
        "$url/users/$userUid",
        headers: await headers,
      );
      final userDataResponseJson = json.decode(userDataResponse.body)['user'];
      userDataResponseJson['lang'] =
          langCodeToLang[userDataResponseJson['lang']];
      if (userDataResponseJson['lang'] == null) {
        userDataResponseJson['lang'] = 'English';
      }
      final userData = json.encode(userDataResponseJson);
      final prefs = await SharedPreferences.getInstance();
      print(userData);
      prefs.setString('userData', userData);
      print(json.decode(prefs.getString('userData')));
      prefs.setString('proposalsSortOption', 'Newly created');
      prefs.setString('eventsSortOption', 'Upcoming');
      prefs.setString('forumSortOption', 'Newly created');
      return json.decode(response.body);
    } catch (error) {
      throw error;
    }
  }

  static Future<Map<String, dynamic>> connectSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return {"errorMessage": "Error"};
    }
    final userData = prefs.getString('userData');
    final userDataMap = json.decode(userData);
    return userDataMap;
  }

  static Future<Map<String, dynamic>> connectVotes(String httpReqType,
      {int pid, int uidUser, int voteVal}) async {
    Map vote = {
      'pid': pid,
      'uid': uidUser,
      'value': voteVal,
    };
    var response = (httpReqType == 'POST') // need pid, uid, and voteVal
        ? await http.post(
            "$url/votes",
            body: json.encode(vote),
            headers: await headers,
          )
        : (httpReqType == 'GET') // need pid and uidUser
            ? await http.get(
                "$url/votes/$pid/$uidUser",
                headers: await headers,
              )
            : await http.patch(
                // need pid, uid, and voteVal
                "$url/votes",
                body: json.encode(vote),
                headers: await headers,
              );
    return json.decode(response.body);
  }

  static Future<List<Comment>> connectComments({int fid}) async {
    final http.Response response = await http.get(
      "$url/comments/forumpost/$fid",
      headers: await headers,
    );

    final sharedPrefs = await connectSharedPreferences();
    final prefLangCode = languages[sharedPrefs['lang']];

    List collection = json.decode(response.body)['comments'];
    List<Comment> _comments =
        collection.map((json) => Comment.fromJson(json, prefLangCode)).toList();
    return _comments;
  }

  static Future<Message> addComment({
    int fid,
    String comment,
    String timestamp,
    int uid,
  }) async {
    final userData = await connectSharedPreferences();
    final response = await http.post(
      "$url/comments",
      body: json.encode({
        'fid': fid,
        'content': comment,
        'timestamp': timestamp,
        'uid': userData['uid'],
      }),
      headers: await headers,
    );
    int status = response.statusCode;
    return status == 201
        ? Message.fromJson(json.decode(response.body)['message'])
        : throw Exception('Message field in comment object not found.');
  }

  static Future<Map<String, dynamic>> connectUser({int uid}) async {
    final http.Response response = await http.get(
      "$url/users/$uid",
      headers: await headers,
    );
    return json.decode(response.body)['user'];
  }

  static Future<Message> changeLanguage({int uid, String updatedLang}) async {
    String updatedLangISO6391Code = languages[updatedLang];
    final response = await http.patch(
      "$url/users/language",
      body: json.encode({
        'uid': uid,
        'lang': updatedLangISO6391Code,
      }),
      headers: await headers,
    );
    int status = response.statusCode;
    return status == 201
        ? Message.fromJson(json.decode(response.body)['message'])
        : throw Exception(
            'Language could not be changed to $updatedLang for user with uid $uid');
  }

  static Future<Message> addEvent({
    String title,
    String description,
    DateTime date,
  }) async {
    final response = await http.post(
      "$url/events",
      body: json.encode({
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
      }),
      headers: await headers,
    );
    int status = response.statusCode;
    return status == 201
        ? Message.fromJson(json.decode(response.body)['message'])
        : throw Exception('Event could not be created.');
  }

  static Future<bool> getAttendance({int eid, int uid}) async {
    final response = await http.get(
      "$url/attenders/$eid/$uid",
      headers: await headers,
    );
    String responseMessage = json.decode(response.body)['message'];
    return responseMessage == 'Error' ? false : true;
  }

  static Future<Message> changeAttendance(
    String httpReqType, {
    int eid,
    int uid,
  }) async {
    http.Response response;
    if (httpReqType == "POST") {
      response = await http.post(
        "$url/attenders",
        body: json.encode({
          'eid': eid,
          'uid': uid,
        }),
        headers: await headers,
      );
      int status = response.statusCode;
      return status == 201
          ? Message.fromJson(json.decode(response.body)['message'])
          : throw Exception(
              'Attendance value of user $uid could not be created for proposal $eid.');
    } else if (httpReqType == "DELETE") {
      response = await http.delete(
        "$url/attenders/$eid/$uid",
        headers: await headers,
      );
      int status = response.statusCode;
      return status == 201
          ? Message.fromJson(json.decode(response.body)['message'])
          : throw Exception(
              'Attendance value of user $uid could not be deleted for proposal $eid.');
    }
    return Message(message: 'Something wrong has happened!');
  }

  static Future<void> vote(int pid, int voteVal) async {
    final prefs = await SharedPreferences.getInstance();
    final userUid = json.decode(prefs.getString('userData'))['uid'];
    connectVotes(
      'POST',
      pid: pid,
      uidUser: userUid,
      voteVal: voteVal,
    );
  }

  static Future<Message> addForumPost(
    String title,
    String description,
    DateTime timestamp,
  ) async {
    final userData = await connectSharedPreferences();
    final response = await http.post(
      "$url/forumposts",
      body: json.encode({
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'uid': userData['uid'],
      }),
      headers: await headers,
    );

    int status = response.statusCode;
    return status == 201
        ? Message.fromJson(json.decode(response.body)['message'])
        : throw Exception('Message field in forum post object not found.');
  }
}
