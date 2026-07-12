import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/location_provider.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locProvider = Provider.of<LocationProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Saved Addresses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: locProvider.savedAddresses.isEmpty
                ? const Center(child: Text('No saved addresses yet.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: locProvider.savedAddresses.length,
                    itemBuilder: (context, index) {
                      final addr = locProvider.savedAddresses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: addr.isDefault ? Border.all(color: AppTheme.accentColor, width: 2) : (isDark ? Border.all(color: Colors.white10) : null),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppTheme.primaryColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addr.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                                  Text(addr.addressString, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (addr.isDefault)
                              const Icon(Icons.check_circle, color: AppTheme.accentColor)
                            else
                              TextButton(
                                onPressed: () => locProvider.setCurrentAddress(addr),
                                child: const Text('SET DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                              )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => locProvider.captureCurrentLocation(),
                icon: const Icon(Icons.my_location),
                label: const Text('ADD CURRENT LOCATION', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
