import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../firebase/firebase_service.dart';

class RegisterController extends ChangeNotifier {
  RegisterController({FirebaseService? service})
    : _service = service ?? FirebaseService();

  final FirebaseService _service;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String fullName,
    required String email,
    required String studentId,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.registerStudent(
        fullName: fullName.trim(),
        email: email.trim(),
        studentId: studentId.trim(),
        phone: phone.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _authErrorMessage(error.code);
      return false;
    } catch (_) {
      _errorMessage = 'Không thể đăng ký. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'invalid-email':
        return 'Email sinh viên không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu chưa đủ an toàn.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      default:
        return 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }
}
