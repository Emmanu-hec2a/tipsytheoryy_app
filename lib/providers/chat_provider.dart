import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/chat_message_model.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  int? _activeOrderId;
  WebSocketChannel? _channel;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  void setActiveOrder(int orderId) {
    if (_activeOrderId == orderId) return;
    
    _activeOrderId = orderId;
    _messages = [];
    stopPolling();
    _closeSocket();
    
    fetchMessages(orderId);
    _initSocket(orderId);
    startPolling(orderId); // Polling remains as fallback
  }

  Future<void> _initSocket(int orderId) async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return;

    final baseUrl = dotenv.env['API_URL'] ?? 'api.tipsytheoryy.com';
    final wsScheme = baseUrl.contains('localhost') ? 'ws' : 'wss';
    final wsUrl = '$wsScheme://$baseUrl/ws/chat/$orderId/?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (data) {
          final Map<String, dynamic> jsonMsg = json.decode(data);
          final message = ChatMessageModel.fromJson(jsonMsg);
          
          // Add if not already present (prevents duplicates with polling)
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            notifyListeners();
          }
        },
        onError: (err) => debugPrint('WebSocket error: $err'),
        onDone: () => debugPrint('WebSocket closed'),
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
    }
  }

  void _closeSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> fetchMessages(int orderId) async {
    try {
      final response = await _apiClient.get('orders/$orderId/chat/');
      if (response.statusCode == 200) {
        final List data = response.data;
        final newMessages = data.map((m) => ChatMessageModel.fromJson(m)).toList();
        
        // Use a more robust check for updates
        if (newMessages.length != _messages.length) {
          _messages = newMessages;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching chat messages: $e');
    }
  }

  Future<bool> sendMessage(int orderId, String text) async {
    if (text.trim().isEmpty) return false;

    // Try socket first for instant feel
    if (_channel != null) {
      try {
        _channel!.sink.add(json.encode({'message': text}));
        return true;
      } catch (e) {
        debugPrint('Socket send failed, falling back to REST: $e');
      }
    }

    try {
      final response = await _apiClient.post('orders/$orderId/chat/', data: {
        'message': text,
      });

      if (response.statusCode == 201) {
        final newMessage = ChatMessageModel.fromJson(response.data);
        if (!_messages.any((m) => m.id == newMessage.id)) {
          _messages.add(newMessage);
          notifyListeners();
        }
        return true;
      }
      
      // Handle the "No Rider Assigned" error from server if it comes as a 400
      if (response.statusCode == 400 && response.data['error'] != null) {
        debugPrint('Send error: ${response.data['error']}');
      }

      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  void startPolling(int orderId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Reduced polling frequency since we have sockets
      fetchMessages(orderId);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeOrderId = null;
    _closeSocket();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
