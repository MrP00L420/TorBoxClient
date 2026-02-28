import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:myapp/models/torrent.dart';
import 'package:myapp/models/user.dart';

class TorboxApi {
  final String _apiKey;
  final String _apiBase = 'https://api.torbox.app';
  final String _apiVersion = 'v1';

  TorboxApi(this._apiKey) {
    developer.log('TorboxApi initialized', name: 'com.myapp.api');
  }

  Future<List<Torrent>> getTorrents() async {
    final url = Uri.parse('$_apiBase/$_apiVersion/api/torrents/mylist');
    developer.log('Fetching torrents from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log('Response status code: ${response.statusCode}', name: 'com.myapp.api');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log('Successfully fetched and decoded torrents.', name: 'com.myapp.api');
          final List<dynamic> data = body['data'];
          return data.map((dynamic item) => Torrent.fromJson(item as Map<String, dynamic>)).toList();
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

  Future<String> getDownloadLink({
    required int torrentId,
    required int fileId,
    bool? zipLink,
    String? userIp,
    bool? redirect,
  }) async {
    final Map<String, String> queryParameters = {
      'token': _apiKey,
      'torrent_id': torrentId.toString(),
      'file_id': fileId.toString(),
    };

    if (zipLink != null) {
      queryParameters['zip_link'] = zipLink.toString();
    }
    if (userIp != null) {
      queryParameters['user_ip'] = userIp;
    }
    if (redirect != null) {
      queryParameters['redirect'] = redirect.toString();
    }

    final url = Uri.parse('$_apiBase/$_apiVersion/api/torrents/requestdl').replace(queryParameters: queryParameters);
    developer.log('Requesting download link from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log('Response status code: ${response.statusCode}', name: 'com.myapp.api');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log('Successfully fetched download link.', name: 'com.myapp.api');
          return body['data'] as String;
        } else {
          throw Exception(body['detail'] ?? 'Failed to get download link');
        }
      } else {
        throw Exception('Failed to get download link: ${response.statusCode}');
      }
    } catch (e, s) {
      developer.log(
        'Error getting download link',
        name: 'com.myapp.api',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
