import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
    _checkConnectivity();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    setState(() {
      _isConnected = isConnected;
      if (!_isConnected) {
        _errorMessage = 'Internet aloqasi yo\'q';
      }
    });
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      setState(() {
        _isConnected = isConnected;
        if (_isConnected) {
          _errorMessage = null;
        } else {
          _errorMessage = 'Internet aloqasi yo\'q';
        }
      });
    });
  }

  Future<void> _handleRefresh() async {
    // Check connectivity first, then reload
    await _checkConnectivity();
    if (_isConnected) {
      await _controller.reload();
    }
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
                      const Icon(Icons.wifi_off, size: 80, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        'Internet aloqasi yo\'q',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Internet yoki Wi-Fi aloqasini tekshiring',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          _handleRefresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF416047),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Qayta urinish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                  // Only show error if it's a network error and we're connected
                  if (_isConnected) {
                    setState(() {
                      _errorMessage = 'Xatolik: ${error.description}';
                    });
                  }
                },
              ),
      ),
    );
  }
}
