import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/user_model.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchProfile();
      Provider.of<RiderProvider>(context, listen: false).fetchRiderData();
    });
  }

  Future<void> _pickImage(UserProvider provider) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isSaving = true);
      final success = await provider.updateProfile(imagePath: image.path);
      setState(() => _isSaving = false);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final riderProvider = Provider.of<RiderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = userProvider.user;
    final summary = riderProvider.earningsSummary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Rider Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await userProvider.fetchProfile();
          await riderProvider.fetchRiderData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildProfileCard(user, userProvider),
              const SizedBox(height: 24),
              _buildStatsRow(summary),
              const SizedBox(height: 32),
              _buildAccountSection(user, userProvider),
              const SizedBox(height: 24),
              _buildPayoutSection(user, userProvider),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('SUPPORT & LEGAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 12),
              _buildMenuCard([
                _buildMenuItem(Icons.history_rounded, 'Delivery History', onTap: () {}),
                _buildMenuItem(Icons.support_agent_rounded, 'Support Center', onTap: () {}),
                _buildMenuItem(Icons.policy_outlined, 'Rider Agreement', onTap: () {}),
              ]),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(context, authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 12),
                      Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel? user, UserProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                backgroundImage: user?.profilePicture != null ? NetworkImage(user!.profilePicture!) : null,
                child: user?.profilePicture == null ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickImage(provider),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                    child: _isSaving 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user?.fullName.isNotEmpty == true ? user!.fullName : user?.username ?? 'Rider Profile',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'rider@tipsytheoryy.com',
            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSimpleStat('${user?.avgRating.toStringAsFixed(1) ?? '0.0'}', 'RATING'),
              Container(width: 1, height: 20, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 30)),
              _buildSimpleStat('${user?.loyaltyPoints ?? 0}', 'XP POINTS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primaryColor)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> summary) {
    return Row(
      children: [
        _buildSummaryStat('TOTAL TRIPS', '${summary['delivery_count'] ?? '0'}', Colors.blue),
        const SizedBox(width: 12),
        _buildSummaryStat('TOTAL EARNED', 'KSh ${summary['total_earned'] ?? '0'}', Colors.green),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(UserModel? user, UserProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(Icons.phone_iphone_rounded, 'Phone Number', subtitle: user?.phone, onTap: () => _editField('phone', user?.phone, provider)),
          _buildMenuItem(Icons.badge_outlined, 'First Name', subtitle: user?.firstName, onTap: () => _editField('first_name', user?.firstName, provider)),
          _buildMenuItem(Icons.badge_outlined, 'Last Name', subtitle: user?.lastName, onTap: () => _editField('last_name', user?.lastName, provider)),
        ]),
      ],
    );
  }

  Widget _buildPayoutSection(UserModel? user, UserProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PAYOUT SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(Icons.account_balance_rounded, 'Bank Name', subtitle: user?.bankName ?? 'Not set', onTap: () => _editField('bank_name', user?.bankName, provider)),
          _buildMenuItem(Icons.person_pin_rounded, 'Account Name', subtitle: user?.bankAccountName ?? 'Not set', onTap: () => _editField('bank_account_name', user?.bankAccountName, provider)),
          _buildMenuItem(Icons.numbers_rounded, 'Account Number', subtitle: user?.bankAccountNumber ?? 'Not set', onTap: () => _editField('bank_account_number', user?.bankAccountNumber, provider)),
        ]),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
    );
  }

  void _editField(String field, String? currentValue, UserProvider provider) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit ${field.replaceAll('_', ' ').toUpperCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isSaving = true);
                  final success = await provider.updateProfile(data: {field: controller.text});
                  setState(() => _isSaving = false);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green));
                  }
                },
                child: const Text('SAVE CHANGES'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}
