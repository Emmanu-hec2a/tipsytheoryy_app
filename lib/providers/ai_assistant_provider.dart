import 'package:flutter/material.dart';
import '../services/ai_voice_service.dart';
import '../models/product_model.dart';
import 'cart_provider.dart';
import 'product_provider.dart';
import 'location_provider.dart';
import 'package:provider/provider.dart';

class AIAssistantProvider with ChangeNotifier {
  final AIVoiceService _voiceService = AIVoiceService();
  
  VoiceState _state = VoiceState.idle;
  String _lastTranscript = "";
  String _aiResponseText = "";
  String? _lastAction;
  Map<String, dynamic>? _lastActionData;
  
  VoiceState get state => _state;
  String get lastTranscript => _lastTranscript;
  String get aiResponseText => _aiResponseText;
  String? get lastAction => _lastAction;
  Map<String, dynamic>? get lastActionData => _lastActionData;

  void setState(VoiceState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> toggleListening(BuildContext context) async {
    if (_state == VoiceState.idle) {
      await startListening();
    } else if (_state == VoiceState.listening) {
      await stopAndProcess(context);
    }
  }

  Future<void> startListening() async {
    try {
      setState(VoiceState.listening);
      await _voiceService.startRecording();
    } catch (e) {
      setState(VoiceState.error);
    }
  }

  Future<void> stopAndProcess(BuildContext context) async {
    try {
      setState(VoiceState.processing);
      final path = await _voiceService.stopRecording();
      
      if (path != null) {
        final locProvider = Provider.of<LocationProvider>(context, listen: false);
        final lat = locProvider.currentAddress?.latitude;
        final lng = locProvider.currentAddress?.longitude;

        final text = await _voiceService.transcribe(path);
        _lastTranscript = text;
        notifyListeners();

        final response = await _voiceService.getAIResponse(text, lat: lat, lng: lng);
        _aiResponseText = response['text'] ?? "";
        _lastAction = response['action'];
        _lastActionData = response['action_data'];
        
        setState(VoiceState.speaking);
        await _voiceService.speak(_aiResponseText);
        
        // Return to idle after speaking (in production, detect when audio ends)
        await Future.delayed(const Duration(seconds: 1));
        
        if (_lastAction != null) {
          _executeAction(context);
        }
        
        setState(VoiceState.idle);
      } else {
        setState(VoiceState.idle);
      }
    } catch (e) {
      setState(VoiceState.error);
      Future.delayed(const Duration(seconds: 3), () => setState(VoiceState.idle));
    }
  }

  void _executeAction(BuildContext context) {
    if (_lastAction == 'NAVIGATE' && _lastActionData != null) {
      final screen = _lastActionData!['screen'];
      Navigator.pushNamed(context, screen);
    } 
    else if (_lastAction == 'ADD_TO_CART' && _lastActionData != null) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      
      // We need to create a dummy product model from action data
      final product = ProductModel(
        id: _lastActionData!['product_id'],
        name: _lastActionData!['name'],
        price: _lastActionData!['price'],
        storeId: _lastActionData!['store_id'],
        isFeatured: false,
      );

      cart.addToCart(
        product, 
        deliveryFee: _lastActionData!['delivery_fee'],
        storeName: _lastActionData!['store_name']
      );
    }
    else if (_lastAction == 'SEARCH_RESULTS' && _lastActionData != null) {
      final prodProvider = Provider.of<ProductProvider>(context, listen: false);
      final query = _lastActionData!['query'];
      prodProvider.search(query);
      
      // Navigate to Home (which displays results when query is active)
      // or a dedicated search screen if it exists.
      // For now, ensure we are on the Home tab if possible.
    }
    
    _lastAction = null; 
    _lastActionData = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
