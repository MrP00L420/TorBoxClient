import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:myapp/models/user.dart';

class TorboxApi {
  final String _apiKey;
  final String _apiBase = 'https://api.torbox.app';
  final String _apiVersion = 'v1';

  TorboxApi(this._apiKey) {
    developer.log('TorboxApi initialized', name: 'com.myapp.api');
  }

  Future<List<dynamic>> getTorrents() async {
    final url = Uri.parse('$_apiBase/$_apiVersion/api/torrents/mylist');
    developer.log('Fetching torrents from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log('Response status code: ${response.statusCode}', name: 'com.myapp.api');
      developer.log('Response body: ${response.body}', name: 'com.myapp.api');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log('Successfully fetched and decoded torrents.', name: 'com.myapp.api');
          return body['data'] as List<dynamic>;
        } else {
          throw Exception(body['detail'] ?? 'Failed to load torrents');
        }
      } else {
        throw Exception('Failed to load torrents: ${response.statusCode}');
      }
    } catch (e, s) {
      developer.log(
        'Error fetching torrents',
        name: 'com.myapp.api',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<User> getUserDetails() async {
    final url = Uri.parse('$_apiBase/$_apiVersion/api/user/me?settings=false');
     developer.log('Fetching user details from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      
      developer.log('User details status code: ${response.statusCode}', name: 'com.myapp.api');
      developer.log('User details response body: ${response.body}', name: 'com.myapp.api');


      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log('Successfully fetched user details.', name: 'com.myapp.api');
          return User.fromJson(body['data'] as Map<String, dynamic>);
        } else {
          throw Exception(body['detail'] ?? 'Failed to load user details');
        }
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e, s) {
       developer.log(
        'Error fetching user details',
        name: 'com.myapp.api',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
