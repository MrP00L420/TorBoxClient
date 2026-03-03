// =============================================================================
// FILE: lib/api.dart
// PURPOSE: TorBox API client wrapper — handles all communication with the
//          TorBox REST API (https://api.torbox.app).
// =============================================================================

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

  // ---------------------------------------------------------------------------
  // getTorrents()
  // Fetches the list of all torrents associated with the user's account.
  // Endpoint: GET /v1/api/torrents/mylist
  // Returns: List<Torrent> — a list of torrent objects parsed from JSON
  // ---------------------------------------------------------------------------
  Future<List<Torrent>> getTorrents() async {
    final url = Uri.parse('$_apiBase/$_apiVersion/api/torrents/mylist');
    developer.log('Fetching torrents from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log(
        'Response status code: ${response.statusCode}',
        name: 'com.myapp.api',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log(
            'Successfully fetched and decoded torrents.',
            name: 'com.myapp.api',
          );
          final List<dynamic> data = body['data'];
          return data
              .map(
                (dynamic item) =>
                    Torrent.fromJson(item as Map<String, dynamic>),
              )
              .toList();
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

  // ---------------------------------------------------------------------------
  // getUserDetails()
  // Fetches the current user's account information (email, premium status, etc).
  // Endpoint: GET /v1/api/user/me?settings=false
  // Returns: User — a user object parsed from JSON
  // ---------------------------------------------------------------------------
  Future<User> getUserDetails() async {
    final url = Uri.parse('$_apiBase/$_apiVersion/api/user/me?settings=false');
    developer.log('Fetching user details from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log(
        'User details status code: ${response.statusCode}',
        name: 'com.myapp.api',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log(
            'Successfully fetched user details.',
            name: 'com.myapp.api',
          );
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

  // ---------------------------------------------------------------------------
  // getDownloadLink()
  // Gets a direct download URL for a single file within a torrent.
  // Only requires torrentId and fileId — no extra parameters.
  // Endpoint: GET /v1/api/torrents/requestdl?token=...&torrent_id=...&file_id=...
  // Returns: String — the direct download URL
  // ---------------------------------------------------------------------------
  Future<String> getDownloadLink({
    required int torrentId,
    required int fileId,
  }) async {
    final Map<String, String> queryParameters = {
      'token': _apiKey,
      'torrent_id': torrentId.toString(),
      'file_id': fileId.toString(),
    };

    final url = Uri.parse(
      '$_apiBase/$_apiVersion/api/torrents/requestdl',
    ).replace(queryParameters: queryParameters);
    developer.log('Requesting download link from: $url', name: 'com.myapp.api');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log(
        'Response status code: ${response.statusCode}',
        name: 'com.myapp.api',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log(
            'Successfully fetched download link.',
            name: 'com.myapp.api',
          );
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

  // ---------------------------------------------------------------------------
  // getZipDownloadLink()
  // Gets a download URL for ALL files in a torrent bundled as a single ZIP.
  // Uses zip_link=true and only requires the torrentId.
  // Endpoint: GET /v1/api/torrents/requestdl?token=...&torrent_id=...&zip_link=true
  // Returns: String — the ZIP download URL
  // ---------------------------------------------------------------------------
  Future<String> getZipDownloadLink({required int torrentId}) async {
    final Map<String, String> queryParameters = {
      'token': _apiKey,
      'torrent_id': torrentId.toString(),
      'file_id': '0',
      'zip_link': 'true',
    };

    final url = Uri.parse(
      '$_apiBase/$_apiVersion/api/torrents/requestdl',
    ).replace(queryParameters: queryParameters);
    developer.log(
      'Requesting ZIP download link from: $url',
      name: 'com.myapp.api',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      developer.log(
        'Response status code: ${response.statusCode}',
        name: 'com.myapp.api',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          developer.log(
            'Successfully fetched ZIP download link.',
            name: 'com.myapp.api',
          );
          return body['data'] as String;
        } else {
          throw Exception(body['detail'] ?? 'Failed to get ZIP download link');
        }
      } else {
        throw Exception(
          'Failed to get ZIP download link: ${response.statusCode}',
        );
      }
    } catch (e, s) {
      developer.log(
        'Error getting ZIP download link',
        name: 'com.myapp.api',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // createTorrent()
  // Adds a new torrent to the user's account using a magnet link.
  // Sends the magnet link as a multipart form field via POST.
  // Endpoint: POST /v1/api/torrents/createtorrent
  // Parameters:
  //   - magnet: the full magnet URI string (e.g., "magnet:?xt=urn:btih:...")
  // Returns: String — success message from the API (shown in SnackBar)
  // ---------------------------------------------------------------------------
  Future<String> createTorrent({required String magnet}) async {
    final url = Uri.parse('$_apiBase/$_apiVersion/api/torrents/createtorrent');
    developer.log(
      'Creating torrent with magnet link at: $url',
      name: 'com.myapp.api',
    );

    try {
      // Use MultipartRequest because TorBox expects form-data for this endpoint
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['magnet'] = magnet;

      // Send the request and convert the streamed response to a regular response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      developer.log(
        'Create torrent status code: ${response.statusCode}',
        name: 'com.myapp.api',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final message =
              body['detail'] as String? ?? 'Torrent added successfully';
          developer.log('Torrent created: $message', name: 'com.myapp.api');
          return message;
        } else {
          throw Exception(body['detail'] ?? 'Failed to create torrent');
        }
      } else {
        // Try to extract an error message from the response body
        try {
          final body = jsonDecode(response.body);
          throw Exception(
            body['detail'] ??
                'Failed to create torrent: ${response.statusCode}',
          );
        } catch (_) {
          throw Exception('Failed to create torrent: ${response.statusCode}');
        }
      }
    } catch (e, s) {
      developer.log(
        'Error creating torrent',
        name: 'com.myapp.api',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
