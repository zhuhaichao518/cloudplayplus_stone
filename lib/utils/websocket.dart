import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

//import 'package:web_socket_channel/io.dart';

class SimpleWebSocket {
  String _url;
  var _socket;
  Function()? onOpen;
  Function(dynamic msg)? onMessage;
  Function(int? code, String? reaso)? onClose;
  SimpleWebSocket(this._url);

  Future<WebSocket> connectToWebSocket(url) async {
    Random r = Random();
    String key = base64Encode(List<int>.generate(8, (_) => r.nextInt(255)));

    HttpClient client = HttpClient(context: SecurityContext());
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true; // trust the certificate
    };

    // Connect to the WebSocket
    var request = await client.getUrl(Uri.parse(url));
    request.headers.add('Connection', 'Upgrade');
    request.headers.add('Upgrade', 'websocket');
    request.headers.add('Sec-WebSocket-Version', '13');
    request.headers.add('Sec-WebSocket-Key', key);

    HttpClientResponse response = await request.close();
    Socket socket = await response.detachSocket();

    var webSocket = WebSocket.fromUpgradedSocket(
      socket,
      protocol: 'signaling',
      serverSide: false,
    );

    return webSocket;
  }

  connect() async {
    try {
      _socket = await WebSocket.connect(_url);
      //_socket = await _connectForSelfSignedCert(_url);
      //_socket = await connectToWebSocket(_url);
      onOpen?.call();
      _socket.listen((data) {
        onMessage?.call(data);
      }, onDone: () {
        onClose?.call(_socket.closeCode, _socket.closeReason);
      });
    } catch (e) {
      onClose?.call(500, e.toString());
    }
  }

  send(data) {
    if (_socket != null) {
      _socket.add(data);
      print('send: $data');
    }
  }

  close() {
    if (_socket != null) _socket.close();
  }

  Future<WebSocket> _connectForSelfSignedCert(url) async {
    try {
      Random r = new Random();
      String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      HttpClient client = HttpClient(context: SecurityContext());
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        print(
            'SimpleWebSocket: Allow self-signed certificate => $host:$port. ');
        return true;
      };

      HttpClientRequest request =
          await client.getUrl(Uri.parse(url)); // form the correct url here
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add(
          'Sec-WebSocket-Version', '13'); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      HttpClientResponse response = await request.close();
      // ignore: close_sinks
      Socket socket = await response.detachSocket();
      var webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );

      return webSocket;
    } catch (e) {
      throw e;
    }
  }
}
