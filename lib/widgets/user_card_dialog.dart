import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserCardDialog extends StatefulWidget {
  final User? user;
  final UserService service;
  final VoidCallback onRefresh;

  const UserCardDialog({
    super.key,
    this.user,
    required this.service,
    required this.onRefresh,
  });

  @override
  State<UserCardDialog> createState() => _UserCardDialogState();
}

class _UserCardDialogState extends State<UserCardDialog> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  XFile? _pickedFile;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!.username;
      _emailController.text = widget.user!.email;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    _pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  Future<void> saveUser() async {
    setState(() => _loading = true);

    try {
      String? uploadedImageUrl;
      if (_pickedFile != null) {
        uploadedImageUrl =
        await widget.service.uploadToCloudinary(_pickedFile!);
      }

      if (widget.user == null) {
        // Thêm user mới
        await widget.service.addUser(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          uploadedImageUrl,
        );
      } else {
        // Cập nhật user
        await widget.service.updateUser(
          widget.user!.id,
          _usernameController.text,
          _emailController.text,
          uploadedImageUrl,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );
      }

      widget.onRefresh();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi lưu user: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa user này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm == true && widget.user != null) {
      setState(() => _loading = true);
      try {
        await widget.service.deleteUser(widget.user!.id);
        widget.onRefresh();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi xóa user: $e')));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user == null ? 'Thêm User Mới' : 'Cập Nhật User',
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: widget.user == null
                      ? 'Password'
                      : 'Mật khẩu mới (tùy chọn)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Chọn ảnh
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_pickedFile != null) ...[
                const SizedBox(height: 8),
                Text(_pickedFile!.name, style: const TextStyle(fontSize: 14)),
              ],
              const SizedBox(height: 24),
              // Buttons: Xóa + Lưu
              Row(
                children: [
                  if (widget.user != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : deleteUser,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Xóa'),
                      ),
                    ),
                  if (widget.user != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : saveUser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Cancel
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
