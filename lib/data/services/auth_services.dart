import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        throw Exception('Registration failed');
      }

      print('Register success, user ID: ${response.user!.id}');

      // Wait for trigger
      await Future.delayed(const Duration(milliseconds: 500));

      // Get user data
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        // Create user manually if trigger didn't work
        print('User not in database, creating manually...');
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'name': name,
        });

        final newUserData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(newUserData);
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      print('Login success, user ID: ${response.user!.id}');

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      print('User data from DB: $userData');

      if (userData == null) {
        print('User not found in database, creating...');
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          'name': response.user!.email?.split('@')[0] ?? 'User',
        });

        final newUserData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(newUserData);
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Get user profile error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({
            if (name != null) 'name': name,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}
