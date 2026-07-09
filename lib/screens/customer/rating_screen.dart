import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class RatingScreen extends StatefulWidget {
  final int orderId;
  const RatingScreen({super.key, required this.orderId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final ApiClient _apiClient = ApiClient();
  int _storeRating = 0;
  int _riderRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_storeRating == 0 || _riderRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide ratings for both store and rider')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _apiClient.post('customer/orders/${widget.orderId}/rate/', data: {
        'store_rating': _storeRating,
        'rider_rating': _riderRating,
        'comment': _commentController.text,
      });

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Rate Your Experience')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.stars_rounded, size: 80, color: AppTheme.accentColor),
                  SizedBox(height: 16),
                  Text(
                    'How was your delivery?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve our service',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildRatingSection('Rate the Store', _storeRating, (val) => setState(() => _storeRating = val)),
            const SizedBox(height: 30),
            _buildRatingSection('Rate the Rider', _riderRating, (val) => setState(() => _riderRating = val)),
            const SizedBox(height: 30),
            const Text('Add a Comment (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                fillColor: Color(0xFFF9FAFB),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, int currentRating, Function(int) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => onRatingChanged(index + 1),
              icon: Icon(
                index < currentRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 40,
              ),
            );
          }),
        ),
      ],
    );
  }
}
