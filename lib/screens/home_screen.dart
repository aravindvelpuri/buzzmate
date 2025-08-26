import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './auth/login_screen.dart';
import './profile/profile_screen.dart';
import './search/user_search_screen.dart';
import './profile/friend_request_screen.dart';
import './chat/chat_list_screen.dart';
import './chat/new_chat_screen.dart';
import './chat/group_create_screen.dart';
import '../theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentUserId;
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _screens = [
      const HomeContentScreen(),
      const Placeholder(), // replaced after userId loads
      const ProfileScreen(),
    ];
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('loggedInUser');
    setState(() {
      _currentUserId = userId;
      if (_currentUserId != null) {
        _screens[1] = UserSearchScreen(currentUserId: _currentUserId!);
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary, // status bar background
        statusBarIconBrightness: Brightness.dark, // white icons (Android)
      ),
      child: Scaffold(
        extendBody: true, // ✅ allows nav bar to float
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: _screens,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                _pageController.jumpToPage(index);
              },
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_outlined),
                  activeIcon: Icon(Icons.chat),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _currentIndex == 0 && _currentUserId != null
            ? CustomFAB(currentUserId: _currentUserId!)
            : null,
      ),
    );
  }
}

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('loggedInUser');
    });
  }

  void _openFriendRequests() {
    if (_currentUserId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendRequestScreen(userId: _currentUserId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ✅ Modern Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "BuzzMate",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, size: 28),
                  onPressed: _openFriendRequests,
                ),
              ],
            ),
          ),

          // ✅ Chat List
          Expanded(
            child: _currentUserId != null
                ? ChatListScreen(currentUserId: _currentUserId!)
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

/// Custom Floating Action Button (Speed Dial)
class CustomFAB extends StatefulWidget {
  final String currentUserId;
  const CustomFAB({super.key, required this.currentUserId});

  @override
  State<CustomFAB> createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotateAnimation =
        Tween<double>(begin: 0, end: 0.125).animate(_controller);
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        _toggle();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand( // ✅ ensures stack fills screen
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isOpen)
            Positioned(
              bottom: 60,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildOption(
                    icon: Icons.chat_bubble_outline,
                    label: "New Chat",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NewChatScreen(currentUserId: widget.currentUserId),
                        ),
                      );
                    },
                  ),
                  _buildOption(
                    icon: Icons.group_add,
                    label: "New Group",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GroupCreateScreen(currentUserId: widget.currentUserId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Main FAB
          Positioned(
            bottom: 0,
            right: 16,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: AppColors.primary,
              child: RotationTransition(
                turns: _rotateAnimation,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
