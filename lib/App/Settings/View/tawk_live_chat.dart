import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TawkLiveChatPage extends StatefulWidget {
  const TawkLiveChatPage({super.key});

  @override
  State<TawkLiveChatPage> createState() => _TawkLiveChatPageState();
}

class _TawkLiveChatPageState extends State<TawkLiveChatPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://tawk.to/chat/697674c1b2c8d0197e1426a6/1jfrbg5jr'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Chat'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
