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
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    try {
      users = await widget.service.fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  void openUserDialog([User? user]) {
    showDialog(
      context: context,
      builder: (_) => UserCardDialog(user: user, service: widget.service, onRefresh: fetchUsers),
    );
  }



  void logout() {
    widget.service.clearToken(); // Xóa token khỏi UserService
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
          : users.isEmpty
          ? const Center(child: Text('No users'))
          : RefreshIndicator(
        onRefresh: fetchUsers,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) => UserTile(
            user: users[index],
            onTap: () => openUserDialog(users[index]),
          ),
        ),
      ),
    );
  }
}
