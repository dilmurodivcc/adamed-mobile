import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LifecarApp(),
    );
  }
}

class LifecarApp extends StatefulWidget {
  const LifecarApp({super.key});

  @override
  State<LifecarApp> createState() => _LifecarAppState();
}

class _LifecarAppState extends State<LifecarApp> {
  late InAppWebViewController _controller;
  late PullToRefreshController _pullToRefreshController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        if (Platform.isAndroid) {
          await _controller.reload();
        } else if (Platform.isIOS) {
          final url = await _controller.getUrl();
          if (url != null) {
            await _controller.loadUrl(urlRequest: URLRequest(url: url));
          } else {
            await _controller.reload();
          }
        } else {
          await _controller.reload();
        }
      },
    );
  }

  Future<void> _handleRefresh() async {
    // Fallback for manual refresh trigger from the error screen button
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _errorMessage != null
            ? Container(
                color: const Color(0xFF416047),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _handleRefresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF416047),
                        ),
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                ),
              )
            : InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri('https://adamed-uz.vercel.app'),
                ),
                pullToRefreshController: _pullToRefreshController,
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  transparentBackground: true,
                  supportZoom: true,
                  userAgent:
                      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                onLoadStop: (controller, url) async {
                  _pullToRefreshController.endRefreshing();
                  setState(() {
                    _errorMessage = null;
                  });
                },
                onReceivedError: (controller, request, error) {
                  _pullToRefreshController.endRefreshing();
                  setState(() {
                    _errorMessage = 'Xatolik: ${error.description}';
                  });
                },
              ),
      ),
    );
  }
}
