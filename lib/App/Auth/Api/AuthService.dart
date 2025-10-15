import 'package:dio/dio.dart';
import 'package:wworker/Constant/urls.dart';



class AuthService {
  
  final Dio _dio = Dio(BaseOptions(baseUrl: Urls.baseUrl));

  Future<Map<String, dynamic>> signup({
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/signup',
        data: {
          "email": email,
          "phoneNumber": phoneNumber,
          "password": password,
        },
      );

      return {
        "success": true,
        "data": response.data,
      };
    } on DioException catch (e) {
 
      return {
        "success": false,
        "message": e.response?.data['message'] ?? e.message,
      };
    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}
