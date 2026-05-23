import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// أصل التطبيق كـ Referer/Origin — مطلوب من YouTube لتجنّب خطأ 153.
const youtubeEmbedRefererOrigin = 'https://com.bayanour.bayanour';

/// نطاق تشغيل iframe (يُمرَّر أيضاً كـ origin في رابط التضمين).
const youtubeEmbedHost = 'https://www.youtube.com';

/// هل يُسمح بالتنقّل داخل WebView لموارد تشغيل YouTube؟
bool youtubeEmbedAllowsNavigation(String url) {
  final u = url.toLowerCase();
  if (u.startsWith('about:') || u.startsWith('data:') || u.startsWith('blob:')) {
    return true;
  }
  const hosts = [
    'youtube.com',
    'youtube-nocookie.com',
    'youtu.be',
    'googlevideo.com',
    'ytimg.com',
    'ggpht.com',
    'gstatic.com',
    'google.com',
    'googleapis.com',
    'doubleclick.net',
    'googleusercontent.com',
  ];
  return hosts.any(u.contains);
}

/// رابط iframe للتضمين مع [origin] صريح للتطبيق.
String youtubeEmbedIframeSrc({String? videoId, String? playlistId}) {
  final origin = Uri.encodeComponent(youtubeEmbedRefererOrigin);
  if (playlistId != null && playlistId.trim().isNotEmpty) {
    final list = Uri.encodeComponent(playlistId.trim());
    return '$youtubeEmbedHost/embed/videoseries?list=$list&playsinline=1&rel=0'
        '&modestbranding=1&enablejsapi=1&autoplay=1&origin=$origin';
  }
  final id = (videoId ?? '').trim();
  return '$youtubeEmbedHost/embed/${Uri.encodeComponent(id)}?playsinline=1&rel=0'
      '&modestbranding=1&enablejsapi=1&fs=1&autoplay=1&origin=$origin';
}

/// HTML كامل بنسبة 16:9 — الطريقة الأكثر ثباتاً على Android WebView.
String youtubeEmbedHtml({String? videoId, String? playlistId}) {
  final src = youtubeEmbedIframeSrc(videoId: videoId, playlistId: playlistId);
  return '''
<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
  iframe { position: fixed; inset: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe
  src="$src"
  title="YouTube"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  allowfullscreen
  referrerpolicy="strict-origin-when-cross-origin">
</iframe>
</body>
</html>
''';
}

/// @deprecated استخدم [createYoutubeEmbedController] — يُبقى للتوافق.
String libraryYoutubeEmbedUrl({String? videoId, String? playlistId}) {
  return youtubeEmbedIframeSrc(videoId: videoId, playlistId: playlistId);
}

/// يُنشئ WebView مُهيّأ لتشغيل YouTube داخل التطبيق.
WebViewController createYoutubeEmbedController({
  required String? videoId,
  required String? playlistId,
  void Function(WebResourceError error)? onWebResourceError,
}) {
  final controller = WebViewController();

  controller
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0xFF000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (youtubeEmbedAllowsNavigation(request.url)) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onWebResourceError: onWebResourceError,
      ),
    )
    ..loadHtmlString(
      youtubeEmbedHtml(videoId: videoId, playlistId: playlistId),
      baseUrl: youtubeEmbedRefererOrigin,
    );

  _configurePlatform(controller);
  return controller;
}

void _configurePlatform(WebViewController controller) {
  if (kIsWeb) return;
  if (!Platform.isAndroid) return;
  final platform = controller.platform;
  if (platform is AndroidWebViewController) {
    platform
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setMixedContentMode(MixedContentMode.alwaysAllow);
  }
}
