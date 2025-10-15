import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wworker/App/Auth/Api/AuthService.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final signupProvider = StateNotifierProvider<SignupNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => SignupNotifier(ref),
);

class SignupNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref; 

  SignupNotifier(this._ref) : super(const AsyncValue.data({}));

  Future<void> signup({
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final service = _ref.read(authServiceProvider); 
    final result = await service.signup(
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );

    if (result['success']) {
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error(result['message'], StackTrace.current);
    }
  }
}


final signinProvider = StateNotifierProvider<SigninNotifier, AsyncValue<Map<String, dynamic>>>(
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