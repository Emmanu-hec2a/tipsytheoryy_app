import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/user_model.dart';
import 'delivery_complete_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Rider Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => authProvider.toggleTheme(),
            icon: Icon(
              authProvider.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context, authProvider),
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await userProvider.fetchProfile();
          await riderProvider.fetchRiderData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildProfileCard(user, userProvider),
              const SizedBox(height: 16),
              _buildStatsRow(summary),
              const SizedBox(height: 24),
              _buildAccountSection(user, userProvider),
              const SizedBox(height: 16),
              _buildPayoutSection(user, userProvider),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('SUPPORT & LEGAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 10),
              _buildMenuCard([
                _buildMenuItem(
                  Icons.history_rounded, 
                  'Delivery History', 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()))
                ),
                _buildMenuItem(
                  Icons.support_agent_rounded, 
                  'Support Center', 
                  onTap: () => _contactSupport()
                ),
                _buildMenuItem(
                  Icons.policy_outlined, 
                  'Rider Agreement', 
                  onTap: () => _viewAgreement()
                ),
                _buildMenuItem(
                  Icons.privacy_tip_outlined, 
                  'Privacy Policy', 
                  onTap: () => _viewPolicy()
                ),
              ]),
              const SizedBox(height: 120), // Extra spacing to ensure last items aren't blocked by floating nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel? user, UserProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                    backgroundImage: user?.profilePicture != null ? NetworkImage(user!.profilePicture!) : null,
                    child: user?.profilePicture == null ? const Icon(Icons.person, size: 35, color: AppTheme.primaryColor) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(provider),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                        child: _isSaving 
                          ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName : user?.username ?? 'Rider Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'rider@tipsytheoryy.com',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleStat('${user?.avgRating.toStringAsFixed(1) ?? '0.0'}', 'RATING'),
              _buildSimpleStat('${user?.loyaltyPoints ?? 0}', 'XP POINTS'),
              _buildSimpleStat('${user?.totalDeliveries ?? 0}', 'TASKS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: isDark ? Colors.white : AppTheme.primaryColor)),
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(UserModel? user, UserProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 10),
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
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('PAYOUT SETTINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 10),
        _buildMenuCard([
          _buildMenuItem(Icons.account_balance_rounded, 'Bank Name', subtitle: user?.bankName ?? 'Not set', onTap: () => _editField('bank_name', user?.bankName, provider)),
          _buildMenuItem(Icons.person_pin_rounded, 'Account Name', subtitle: user?.bankAccountName ?? 'Not set', onTap: () => _editField('bank_account_name', user?.bankAccountName, provider)),
          _buildMenuItem(Icons.numbers_rounded, 'Account Number', subtitle: user?.bankAccountNumber ?? 'Not set', onTap: () => _editField('bank_account_number', user?.bankAccountNumber, provider)),
        ]),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)) : null,
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white10 : Colors.grey, size: 20),
    );
  }

  void _editField(String field, String? currentValue, UserProvider provider) {
    final controller = TextEditingController(text: currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit ${field.replaceAll('_', ' ').toUpperCase()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
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

  void _contactSupport() async {
    const phone = "+254700000000"; // TODO: Replace with official TipsyTheoryy support
    final url = Uri.parse("https://wa.me/$phone?text=Hello TipsyTheoryy Support, I'm a Rider and I need help.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _viewAgreement() async {
    final url = Uri.parse("https://tipsytheoryy.com/legal/rider-agreement/");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _viewPolicy() async {
    final url = Uri.parse("https://tipsytheoryy.com/legal/privacy-policy/");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
