import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/user_model.dart';
import 'saved_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'favourites_screen.dart';
import 'support_legal_screen.dart';
import 'legal_content_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchProfile();
    });
  }

  Future<void> _pickImage(UserProvider provider) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final success = await provider.updateProfile(imagePath: image.path);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🛡️ Required for AutomaticKeepAliveClientMixin
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = userProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildCollapsingHeader(user, userProvider),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (userProvider.isLoading && user == null)
                  _buildProfileSkeletons(context)
                else if (userProvider.error != null && user == null)
                   Padding(
                    padding: const EdgeInsets.all(50),
                    child: Center(child: Text(userProvider.error!, style: const TextStyle(color: Colors.red))),
                  )
                else ...[
                  _buildLoyaltyCard(user?.loyaltyPoints ?? 0, userProvider),
                  if ((user?.walletBalance ?? 0) > 0) _buildWalletCard(user!.walletBalance),
                  const SizedBox(height: 8),
                  _buildSectionTitle('Account Settings'),
                  _buildMenuCard([
                    _buildMenuItem(Icons.person_outline_rounded, 'Personal Information', onTap: () => _showEditProfile(context, userProvider)),
                    _buildMenuItem(Icons.location_on_outlined, 'Saved Addresses', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen()))),
                    _buildMenuItem(Icons.payment_rounded, 'Payment Methods', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
                  ]),
                  _buildSectionTitle('Orders & Activity'),
                  _buildMenuCard([
                    _buildMenuItem(Icons.shopping_bag_outlined, 'My Orders', onTap: () => Navigator.pushNamed(context, '/orders')),
                    _buildMenuItem(Icons.favorite_outline_rounded, 'My Favourites', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouritesScreen()))),
                    _buildMenuItem(Icons.star_outline_rounded, 'Rate the App', onTap: () => _showFeedbackDialog(context)),
                  ]),
                  _buildSectionTitle('Support & Legal'),
                  _buildMenuCard([
                    _buildMenuItem(
                      Icons.coffee_rounded, 
                      'Support Developer', 
                      onTap: () => _launchSupportUrl(),
                    ),
                    _buildMenuItem(Icons.headset_mic_outlined, 'Help & Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportLegalScreen()))),
                  ]),
                  const SizedBox(height: 120), // Extra spacing to ensure last items aren't blocked by floating nav
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsingHeader(UserModel? user, UserProvider provider) {
    final topPadding = MediaQuery.of(context).padding.top;
    const collapsedHeight = 56.0;
    const expandedContentHeight = 140.0;
    final expandedHeight = topPadding + expandedContentHeight;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
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
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = collapsedHeight + topPadding;
          final expandRatio = ((constraints.maxHeight - minHeight) / (expandedHeight - minHeight))
              .clamp(0.0, 1.0);

          return ClipRect(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFF1B4D42)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 20,
                    right: 20,
                    top: topPadding,
                    height: collapsedHeight,
                    child: IgnorePointer(
                      ignoring: expandRatio > 0.5,
                      child: Opacity(
                        opacity: (1 - expandRatio * 2).clamp(0.0, 1.0),
                        child: Row(
                          children: [
                            _buildProfileAvatar(user, provider, radius: 18, showCamera: false),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                user?.fullName.isNotEmpty == true ? user!.fullName : 'Welcome Back',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: topPadding,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: expandRatio < 0.5,
                      child: Opacity(
                        opacity: ((expandRatio - 0.5) * 2).clamp(0.0, 1.0),
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildProfileAvatar(user, provider, radius: 32, showCamera: true),
                                  const SizedBox(height: 10),
                                  Text(
                                    user?.fullName.isNotEmpty == true ? user!.fullName : 'Welcome Back',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? '',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel? user, UserProvider provider, {required double radius, required bool showCamera}) {
    final size = radius * 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentColor, width: radius > 30 ? 3 : 2),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: user?.profilePicture != null
                  ? CachedNetworkImage(
                      imageUrl: user!.profilePicture!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade100,
                        highlightColor: Colors.white,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.person, size: radius, color: AppTheme.primaryColor),
                    )
                  : Icon(Icons.person, size: radius, color: AppTheme.primaryColor),
            ),
          ),
        ),
        if (showCamera)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickImage(provider),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoyaltyCard(int points, UserProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5A059), Color(0xFFA67C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOYALTY POINTS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('$points Points', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => _showRedeemDialog(context, provider),
              child: const Text('REDEEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(double balance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIPSY CREDIT', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('KSh ${balance.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Text('Ready to use', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: items),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 20),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to log out of TipsyTheoryy?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              await auth.logout(onLogout: () {
                Provider.of<UserProvider>(context, listen: false).clear();
                Provider.of<CartProvider>(context, listen: false).clear();
                Provider.of<OrderProvider>(context, listen: false).clear();
                Provider.of<RiderProvider>(context, listen: false).clear();
              });
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, UserProvider provider) {
    final points = provider.user?.loyaltyPoints ?? 0;
    final value = points / 100;
    final canRedeem = points >= 1000;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFC5A059)),
            const SizedBox(width: 10),
            Text('Redeem Points', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available: $points Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 8),
            Text('Cash Value: KSh ${value.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 20),
            Text(
              canRedeem 
                ? 'Would you like to convert all your points into Tipsy Credit?' 
                : 'You need at least 1,000 points to redeem. Keep ordering to earn more!',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CLOSE', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold))),
          if (canRedeem)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final result = await provider.redeemPoints();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success'] ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('REDEEM NOW'),
            ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Rate your experience', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('We are not on the App Store yet, but we\'d love to hear your feedback!', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Tell us what you think...',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, UserProvider provider) {
    final firstNameController = TextEditingController(text: provider.user?.firstName);
    final lastNameController = TextEditingController(text: provider.user?.lastName);
    final phoneController = TextEditingController(text: provider.user?.phone);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
              const SizedBox(height: 24),
              _buildTextField('First Name', firstNameController, isDark),
              const SizedBox(height: 16),
              _buildTextField('Last Name', lastNameController, isDark),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', phoneController, isDark),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await provider.updateProfile(
                      data: {
                        'first_name': firstNameController.text,
                        'last_name': lastNameController.text,
                        'phone': phoneController.text,
                      }
                    );
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white38 : AppTheme.primaryColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSkeletons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkShimmerBase : AppTheme.shimmerBase;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : AppTheme.shimmerHighlight;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                height: 60,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _launchSupportUrl() async {
    final Uri url = Uri.parse('https://selar.com/showlove/tipsytheoryy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch support link')),
        );
      }
    }
  }
}
