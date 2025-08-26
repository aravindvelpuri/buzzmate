import 'package:buzzmate/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  final String currentUserId;

  const UserSearchScreen({super.key, required this.currentUserId});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final usernameQuery = _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '${query}z')
          .limit(10);

      final fullNameQuery = _firestore
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThan: '${query}z')
          .limit(10);

      final usernameResults = await usernameQuery.get();
      final fullNameResults = await fullNameQuery.get();

      final allResults = [...usernameResults.docs, ...fullNameResults.docs];
      final uniqueResults =
          allResults.fold<Map<String, DocumentSnapshot>>({}, (map, doc) {
        map[doc.id] = doc;
        return map;
      }).values.toList();

      final filteredResults =
          uniqueResults.where((doc) => doc.id != widget.currentUserId).toList();

      setState(() {
        _searchResults = filteredResults.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'username': data['username'] ?? 'Unknown',
            'fullName': data['fullName'] ?? '',
            'profileImageUrl': data['profileImageUrl'],
          };
        }).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary, // status bar background color
        statusBarIconBrightness: Brightness.dark, // white icons (Android)
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // 🔎 Custom Search Bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_search,
                                    size: 80, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isEmpty
                                      ? "Search for users by username or name"
                                      : "No users found",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    backgroundImage: user['profileImageUrl'] !=
                                                null &&
                                            user['profileImageUrl'].isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user['profileImageUrl'])
                                        : null,
                                    child: user['profileImageUrl'] == null ||
                                            user['profileImageUrl'].isEmpty
                                        ? const Icon(Icons.person,
                                            size: 30, color: AppColors.primary)
                                        : null,
                                  ),
                                  title: Text(
                                    user['username'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    user['fullName'],
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfileScreen(
                                            profileUserId: user['id']),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
