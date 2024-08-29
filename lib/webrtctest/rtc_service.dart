abstract class RTCService {
  Future<Map<String, dynamic>> get(String url);
  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body);
  Future<Map<String, dynamic>> login(String username, String password);
  Future<List<dynamic>> fetchGames({String? searchQuery, String? genre});
  Future<bool> isLoggedIn();
}
