import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class UserService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.2.42:5001/api',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  String? _token;

  void clearToken() => _token = null;


  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Fetch all users
  Future<List<User>> fetchUsers() async {
    final resp = await _dio.get('/users/getUsers');
    final data = resp.data['users'] ?? resp.data;
    return List<User>.from(data.map((e) => User.fromJson(e)));
  }

  // Add user
  Future<void> addUser(String username, String email, String password, String? imageUrl) async {
    await _dio.post('/users/addUser', data: {
      'username': username,
      'email': email,
      'password': password,
      'image': imageUrl ?? '',
    });
  }

  // Update user
  Future<void> updateUser(String id, String username, String email, String? imageUrl) async {
    await _dio.put('/users/updateUser/$id', data: {
      'username': username,
      'email': email,
      if (imageUrl != null) 'image': imageUrl,
    });
  }

  // Delete user
  Future<void> deleteUser(String id) async {
    await _dio.delete('/users/deleteUser/$id');
  }

  // Upload image to Cloudinary
  Future<String?> uploadToCloudinary(XFile file) async {
    try {
      FormData formData;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: file.name),
          'upload_preset': 'ml_default',
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
          'upload_preset': 'ml_default',
        });
      }

      final response = await Dio().post(
        'https://api.cloudinary.com/v1_1/de19voxxj/image/upload',
        data: formData,
      );

      return response.data['secure_url'];
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
