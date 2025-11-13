import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wworker/App/Product/Api/ProService.dart';

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(),
);
