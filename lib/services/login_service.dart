import 'dart:convert';
import 'dart:io';
import 'package:cloudplayplus/dev_settings.dart/develop_settings.dart';
import 'package:cloudplayplus/services/app_info_service.dart';
import 'package:cloudplayplus/services/secure_storage_manager.dart';
import 'package:cloudplayplus/services/shared_preferences_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../entities/user.dart' as cpp_user;

//build commands:
//flutter run -d chrome --web-browser-flag "--disable-web-security"
//flutter build web --local-web-sdk=host_debug --no-tree-shake-icons
//flutter build web --local-web-sdk=host_debug --no-tree-shake-icons --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://cdn.jsdelivr.net/npm/canvaskit-wasm@0.39.1/bin/
//flutter build web --local-web-sdk=host_debug --no-tree-shake-icons --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/

//flutter run -d chrome --web-browser-flag "--disable-web-security"

//macos build web:
//flutter build web --local-web-sdk=wasm_release
//flutter build web --local-web-sdk=wasm_release --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=canvaskit/
class LoginService {
  //run python manage.py runserver 8000 before testing.
  //sudo service redis-server start before run server on windows WSL.
  static String _baseUrl = 'https://www.cloudplayplus.com';

  static void init() {
    if (DevelopSettings.useLocalServer) {
      if (AppPlatform.isAndroid) {
        //_baseUrl = "http://10.0.2.2:8000";
        // run adb reverse tcp:8000 tcp:8000 to forward request to 127.0.0.1
        _baseUrl = "http://127.0.0.1:8000";
      } else {
        _baseUrl = "http://127.0.0.1:8000";
      }
    }
  }

  static Future<http.Response> customHttpPost(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) async {
    final client = HttpClient(context: SecurityContext())
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final request = await client.postUrl(url);

    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
    }

    request.headers.contentType = ContentType.json;
    if (body != null && encoding != null) {
      request.write(encoding.encode(json.encode(body)));
    } else if (body != null) {
      request.write(json.encode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    client.close();

    Map<String, String> headerMap = {};
    response.headers.forEach((key, values) {
      headerMap[key] = values.join(', ');
    });
    return http.Response(responseBody, response.statusCode, headers: headerMap);
  }

  static Future<String?> _refreshToken(String refreshToken) async {
    Uri refreshTokenEndpoint = Uri.parse('$_baseUrl/api/token/refresh/');
    final response = await http.post(
      refreshTokenEndpoint,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'refresh': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody != null && responseBody.containsKey('access')) {
        return responseBody['access'];
      }
    }

    // In case of any error, return null
    return null;
  }

  Future<String> requestNickName(String uid) async {
    Uri url = Uri.parse('$_baseUrl/api/requestnickname/');
    http.Response response;
    try {
      if (!DevelopSettings.useLocalServer) {
        response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'uid': uid,
          }),
        );
      } else {
        response = await http.post(
          url,
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': '*/*'
          },
          body: jsonEncode(<String, String>{
            'uid': uid,
          }),
        );
      }
    } catch (e) {
      return "error:网络连接失败";
    }

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      return responseBody['nickname'];
    }
    return "未找到用户。您输入的UID不正确。";
  }

  Future<bool> updateUserInfo(cpp_user.User user) async {
    Uri url = Uri.parse('$_baseUrl/api/updateuserinfo/');
    String? accessToken;
    if (DevelopSettings.useSecureStorage) {
      accessToken = await SecureStorageManager.getString('access_token');
    } else {
      accessToken = SharedPreferencesManager.getString('access_token');
    }

    http.Response response;
    try {
      if (!DevelopSettings.useLocalServer) {
        response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'token': accessToken!,
            'newname': user.nickname,
          }),
        );
      } else {
        response = await http.post(
          url,
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': '*/*'
          },
          body: jsonEncode(<String, String>{
            'token': accessToken!,
            'newname': user.nickname,
          }),
        );
      }
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  static Future<bool> loginWithToken(String accessToken) async {
    Uri url = Uri.parse('$_baseUrl/api/tokenlogin/');
    http.Response response;
    try {
      if (!DevelopSettings.useLocalServer) {
        response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'token': accessToken,
          }),
        );
      } else {
        response = await http.post(
          url,
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': '*/*'
          },
          body: jsonEncode(<String, String>{
            'token': accessToken,
          }),
        );
      }
    } catch (e) {
      return false;
    }

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      //final prefs = await SharedPreferences.getInstance();
      //prefs.setString('access_token', responseBody['access']);
      //prefs.setString('refresh_token', responseBody['refresh']);

      if (DevelopSettings.useSecureStorage) {
        await SecureStorageManager.setString(
            'access_token', responseBody['access']);
        await SecureStorageManager.setString(
            'refresh_token', responseBody['refresh']);
      } else {
        await SharedPreferencesManager.setString(
            'access_token', responseBody['access']);
        await SharedPreferencesManager.setString(
            'refresh_token', responseBody['refresh']);
      }

      //TODO(haichao):update user
      /*ApplicationInfoServiceImpl().user = cppUser.User(
          uid: int.parse(responseBody['uid']),
          nickname: responseBody['nickname'],
          chattoken: responseBody['chattoken']);*/
      return true;
    }
    return false;
  }

  //TODO(haichao):refresh refresh token
  static Future<bool> tryLoginWithCachedToken() async {
    String? accessToken;
    String? refreshToken;
    if (DevelopSettings.useSecureStorage) {
      accessToken = await SecureStorageManager.getString('access_token');
      refreshToken = await SecureStorageManager.getString('refresh_token');
    } else {
      accessToken = SharedPreferencesManager.getString('access_token');
      refreshToken = SharedPreferencesManager.getString('refresh_token');
    }
    if (accessToken == null ||
        refreshToken == null ||
        accessToken == "" ||
        refreshToken == "") {
      return false;
    } else if (isTokenValid(accessToken)) {
      return await loginWithToken(accessToken);
    } else {
      final newAccessToken = await _refreshToken(refreshToken!);
      if (newAccessToken != null && isTokenValid(newAccessToken)) {
        if (DevelopSettings.useSecureStorage) {
          await SecureStorageManager.setString('access_token', newAccessToken);
        } else {
          await SharedPreferencesManager.setString(
              'access_token', newAccessToken);
        }
        return await loginWithToken(newAccessToken);
      } else {
        return false;
      }
    }
  }

  static bool isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      // Get the payload, which is the second part of the JWT
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(resp) as Map<String, dynamic>;

      if (payloadMap.containsKey('exp')) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final expiry = (payloadMap['exp'] as int) *
            1000; // Convert seconds to milliseconds

        if (expiry > now) {
          // Token is still valid
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String url) async {
    final response = await http.get(Uri.parse('$_baseUrl/$url'));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String url, Map<String, dynamic> body) async {
    final response =
        await http.post(Uri.parse('$_baseUrl/$url'), body: jsonEncode(body));
    return _handleResponse(response);
  }

  // ...

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      String errdesc = response.statusCode.toString();
      if (response.statusCode == 401) errdesc = "用户名或密码不正确";
      if (response.statusCode == 400) errdesc = "用户名或邮箱已被注册过";
      Map<String, dynamic> result = {'status': 'fail', 'message': errdesc};
      return result;
      //throw Exception(/*response.statusCode.toString() + */ errdesc);
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    //final Uri url = Uri.https('www.cloudplayplus.com', '/api/login/');
    Uri url = Uri.parse('$_baseUrl/api/login/');
    http.Response response;

    try {
      if (!kIsWeb && DevelopSettings.useUnsafeServer) {
        _baseUrl = 'https://101.132.58.198';
        response = await customHttpPost(
          url,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: {
            'username': username,
            'password': password,
          },
        );
      } else if (!DevelopSettings.useLocalServer) {
        response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'password': password,
          }),
        );
      } else {
        response = await http.post(
          url,
          headers: <String, String>{
            "Access-Control-Allow-Origin": "*",
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': '*/*'
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'password': password,
          }),
        );
      }
    } catch (e) {
      return ({"status": "fail", "message": "网络连接失败。请检查网络"});
    }

    /*final response = await customHttpPost(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: {
        'username': username,
        'password': password,
      },
    );*/

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      //final prefs = await SharedPreferences.getInstance();
      //prefs.setString('access_token', responseBody['access']);
      //prefs.setString('refresh_token', responseBody['refresh']);
      if (DevelopSettings.useSecureStorage) {
        await SecureStorageManager.setString(
            'access_token', responseBody['access']);
        await SecureStorageManager.setString(
            'refresh_token', responseBody['refresh']);
        await SecureStorageManager.setString('username', username);
        await SecureStorageManager.setString('password', password);
      } else {
        await SharedPreferencesManager.setString(
            'access_token', responseBody['access']);
        await SecureStorageManager.setString('username', username);
        //不安全 就不保存密码了
      }
      /*TODO(haichao):update app state
      ApplicationInfoServiceImpl().user = cppUser.User(
          uid: int.parse(responseBody['uid']),
          nickname: responseBody['nickname'],
          chattoken: responseBody['chattoken']);
      //await StreamChatServiceImpl.initChatService();
      */
      Map<String, dynamic> result = {
        'status': 'success',
      };
      return result;
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(
      String username, String password, String email, String nickname) async {
    //final Uri url = Uri.https('www.cloudplayplus.com', '/api/login/');
    Uri url = Uri.parse('$_baseUrl/api/register/');
    if (DevelopSettings.useLocalServer) {
      url = Uri.parse('http://127.0.0.1:8000/api/register/');
    }

    http.Response response;
    try {
      response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
          'email': email,
          'nickname': nickname,
        }),
      );
    } catch (e) {
      return ({"status": "fail", "message": "网络连接失败。请检查网络"});
    }

    if (response.statusCode == 201) {
      //final prefs = await SharedPreferences.getInstance();
      //final responseBody = json.decode(response.body);
      //prefs.setString('access_token', responseBody['access']);
      //prefs.setString('refresh_token', responseBody['refresh']);
      Map<String, dynamic> result = {
        'status': 'success',
      };
      return result;
    }
    return _handleResponse(response);
  }

  Future<List<dynamic>> fetchGames({String? searchQuery, String? genre}) async {
    String queryUrl = '$_baseUrl/api/games';

    if (searchQuery != null || genre != null) {
      queryUrl += '?';
      if (searchQuery != null) {
        queryUrl += 'search=$searchQuery';
      }
      if (genre != null) {
        queryUrl += (searchQuery != null) ? '&genre=$genre' : 'genre=$genre';
      }
    }

    final response = await http.get(Uri.parse(queryUrl));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to load games");
    }
  }
}
