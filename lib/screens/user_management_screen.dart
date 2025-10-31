import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/user_tile.dart';
import '../widgets/user_card_dialog.dart';
import 'login_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final UserService service;
  const UserManagementScreen({super.key, required this.service});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> users = [];
  List<User> filteredUsers = [];
  bool loading = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    try {
      users = await widget.service.fetchUsers();
      applySearch(searchQuery); // Áp dụng tìm kiếm sau khi fetch
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void applySearch(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredUsers = List.from(users);
      } else {
        filteredUsers = users.where((user) {
          final lowerQuery = query.toLowerCase();
          return user.username.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void openUserDialog([User? user]) {
    showDialog(
      context: context,
      builder: (_) => UserCardDialog(
        user: user,
        service: widget.service,
        onRefresh: fetchUsers,
      ),
    );
  }

  void logout() {
    widget.service.clearToken();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(onPressed: fetchUsers, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openUserDialog(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by username or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: applySearch,
            ),
          ),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text('No users found'))
                : RefreshIndicator(
              onRefresh: fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) => UserTile(
                  user: filteredUsers[index],
                  onTap: () => openUserDialog(filteredUsers[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}