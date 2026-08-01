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
      body: Stack(
        children: [
          Column(
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
                              border: addr.isDefault ? Border.all(color: AppTheme.accentColor, width: 2) : null,
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
                                else ...[
                                  TextButton(
                                    onPressed: () async {
                                      locProvider.setCurrentAddress(addr);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${addr.name} set as default')),
                                      );
                                    },
                                    child: const Text('SET DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showDeleteConfirmation(context, locProvider, addr),
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: locProvider.isLoading ? null : () async {
                        await locProvider.captureCurrentLocation();
                        if (context.mounted) {
                          if (locProvider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(locProvider.error!), backgroundColor: Colors.red),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address added successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      },
                      icon: locProvider.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.my_location),
                      label: Text(
                        locProvider.isLoading ? 'LOCATING...' : 'ADD CURRENT LOCATION', 
                        style: const TextStyle(fontWeight: FontWeight.w900)
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (locProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                        SizedBox(height: 16),
                        Text('Processing...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, LocationProvider provider, dynamic addr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${addr.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteAddress(addr.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Address removed' : 'Failed to remove address'),
                    backgroundColor: success ? Colors.black87 : Colors.red,
                  ),
                );
              }
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
