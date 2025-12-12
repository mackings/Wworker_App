import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';




final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ============================================================
// SIGNUP PROVIDER - Company info now optional
// ============================================================
final signupProvider =
    StateNotifierProvider<SignupNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => SignupNotifier(ref),
);

class SignupNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;

  SignupNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> signup({
    required String fullname,
    required String email,
    required String phoneNumber,
    required String password,
    String? companyName,
    String? companyEmail,
  }) async {
    state = const AsyncValue.loading();

    final service = _ref.read(authServiceProvider);
    final result = await service.signup(
      fullname: fullname,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      companyName: companyName,
      companyEmail: companyEmail,
    );

    if (result['success'] == true) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result['message'], StackTrace.current);
    }
  }
}

// ============================================================
// SIGNIN PROVIDER
// ============================================================
final signinProvider =
    StateNotifierProvider<SigninNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => SigninNotifier(ref),
);

class SigninNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;

  SigninNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final service = _ref.read(authServiceProvider);
    final result = await service.signin(email: email, password: password);

    if (result["success"] == true) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result["message"], StackTrace.current);
    }
  }
}


// ============================================================
// CHANGE PASSWORD PROVIDER - NEW
// ============================================================
final changePasswordProvider = StateNotifierProvider<ChangePasswordNotifier,
    AsyncValue<Map<String, dynamic>>>(
  (ref) => ChangePasswordNotifier(ref),
);

class ChangePasswordNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;

  ChangePasswordNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();

    final service = _ref.read(authServiceProvider);
    final result = await service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (result["success"] == true) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result["message"], StackTrace.current);
    }
  }
}

// ============================================================
// GET ME PROVIDER
// ============================================================
final getMeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getMe();
});

// ============================================================
// FORGOT PASSWORD PROVIDER
// ============================================================
final forgotPasswordProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, method) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.forgotPassword(method: method);
});

// ============================================================
// VERIFY OTP PROVIDER
// ============================================================
final verifyOtpProvider = StateNotifierProvider<VerifyOtpNotifier,
    AsyncValue<Map<String, dynamic>>>(
  (ref) => VerifyOtpNotifier(ref),
);

class VerifyOtpNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;

  VerifyOtpNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> verifyOtp({required String otp}) async {
    state = const AsyncValue.loading();

    final service = _ref.read(authServiceProvider);
    final result = await service.verifyOtp(otp: otp);

    if (result["success"] == true) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result["message"], StackTrace.current);
    }
  }
}

// ============================================================
// RESET PASSWORD PROVIDER
// ============================================================
final resetPasswordProvider = StateNotifierProvider<ResetPasswordNotifier,
    AsyncValue<Map<String, dynamic>>>(
  (ref) => ResetPasswordNotifier(ref),
);

class ResetPasswordNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;

  ResetPasswordNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> resetPassword({required String password}) async {
    state = const AsyncValue.loading();

    final service = _ref.read(authServiceProvider);
    final result = await service.resetPassword(password: password);

    if (result["success"] == true) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result["message"], StackTrace.current);
    }
  }
}

// ============================================================
// LOGOUT PROVIDER
// ============================================================
final logoutProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.logout();
});