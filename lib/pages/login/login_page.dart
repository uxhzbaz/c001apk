import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../constants/constants.dart';
import '../../utils/storage_util.dart';
import '../../utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = AndroidWebView();
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            final cookies = await _getCookies();
            final uid = _extractCookie(cookies, 'uid');
            final token = _extractCookie(cookies, 'token');
            final username = _extractCookie(cookies, 'username');
            if (uid != null && token != null && username != null) {
              GStorage.setUid(uid);
              GStorage.setUsername(username);
              GStorage.setToken(token);
              GStorage.setIsLogin(true);
              SmartDialog.showToast('登录成功');
              Get.back(result: true);
            }
          },
          onUrlChange: (UrlChange change) async {
            final url = change.url ?? '';
            if (url.contains('account.coolapk.com/auth/loginByCoolApk') ||
                url.contains('www.coolapk.com')) {
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(Constants.URL_LOGIN));
  }
  Future<Map<String, String>> _getCookies() async {
    try {
      final cookieManager = WebViewCookieManager();
      final cookies = await cookieManager.getCookies(Constants.URL_LOGIN);
      final Map<String, String> cookieMap = {};
      for (var cookie in cookies) {
        cookieMap[cookie.name] = cookie.value;
      }
      return cookieMap;
    } catch (e) {
      debugPrint('获取Cookie失败: $e');
      return {};
    }
  }
  String? _extractCookie(Map<String, String> cookies, String key) {
    return cookies[key];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网页登录'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}