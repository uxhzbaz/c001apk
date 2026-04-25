import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

import '../../constants/constants.dart';
import '../../utils/extensions.dart';
import '../../utils/global_data.dart';
import '../../utils/storage_util.dart';
import '../../utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final InAppWebViewController _webViewController;
  final _progressStream = StreamController<double>();

  @override
  void initState() {
    super.initState();
    // 可选：清空旧 Cookie
    CookieManager().deleteAllCookies();
  }

  @override
  void dispose() {
    _progressStream.close();
    super.dispose();
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
        bottom: PreferredSize(
          preferredSize: Size.zero,
          child: StreamBuilder(
            initialData: 0.0,
            stream: _progressStream.stream,
            builder: (_, snapshot) => snapshot.data as double < 1
                ? LinearProgressIndicator(value: snapshot.data as double)
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: InAppWebView(
        initialSettings: InAppWebViewSettings(
          useHybridComposition: false,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          useShouldOverrideUrlLoading: true,
          clearCache: true,
          userAgent: GStorage.userAgent,
          forceDark: ForceDark.AUTO,
          algorithmicDarkeningAllowed: true,
        ),
        initialUrlRequest: URLRequest(
          url: WebUri.uri(Uri.parse(Constants.URL_LOGIN)),
          headers: {'X-Requested-With': Constants.APP_ID},
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onProgressChanged: (controller, progress) {
          _progressStream.add(progress / 100);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url!.toString();
          if (url == Constants.URL_COOLAPK) {
            // 获取 Cookie 中的登录信息
            final uidCookie = await CookieManager().getCookie(
              url: WebUri.uri(Uri.parse(Constants.URL_COOLAPK)),
              name: 'uid',
            );
            final usernameCookie = await CookieManager().getCookie(
              url: WebUri.uri(Uri.parse(Constants.URL_COOLAPK)),
              name: 'username',
            );
            final tokenCookie = await CookieManager().getCookie(
              url: WebUri.uri(Uri.parse(Constants.URL_COOLAPK)),
              name: 'token',
            );

            if (uidCookie != null &&
                usernameCookie != null &&
                tokenCookie != null) {
              GStorage.setUid(uidCookie.value);
              GStorage.setUsername(usernameCookie.value);
              GStorage.setToken(tokenCookie.value);
              GStorage.setIsLogin(true);
              SmartDialog.showToast('登录成功');
              Get.back(result: true);
            } else {
              SmartDialog.showToast('登录失败, 未获取到凭证');
              Get.back(result: false);
            }
            return NavigationActionPolicy.CANCEL;
          }
          if (!url.startsWith('http')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('将要打开外部链接,请确认'),
                showCloseIcon: true,
                action: SnackBarAction(
                  label: '打开',
                  onPressed: () => Utils.launchURL(url),
                ),
              ),
            );
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}