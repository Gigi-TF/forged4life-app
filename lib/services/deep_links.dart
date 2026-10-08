import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/auth_screen.dart';
import '../screens/session_detail_screen.dart';
import 'card_store.dart';

/// Handles links that open the app from outside it.
///
/// A link is a stranger's first contact as often as a member's, so this has to
/// cope with three states: signed in, signed out, and not a member at all.
/// Dropping someone on a login wall when they tapped "reserve your seat" is
/// how you lose the registration the link was for.
class DeepLinks {
  DeepLinks._();
  static final instance = DeepLinks._();

  final _links = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Set by the app's root so a link can navigate from outside a widget.
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> start() async {
    // The link that launched a cold start. getInitialLink fires once and only
    // on first launch — the stream below never sees it.
    final initial = await _links.getInitialLink();
    if (initial != null) {
      await _handle(initial);
    }

    // Links that arrive while the app is already running.
    _sub = _links.uriLinkStream.listen(_handle);
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<void> _handle(Uri uri) async {
    final parts = uri.pathSegments;

    if (parts.isEmpty) return;

    if (parts.first == 'sessions' && parts.length >= 2) {
      await _openSession(parts[1]);
    }
  }

  Future<void> _openSession(String slug) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final token = await CardStore.readAuthToken();

    if (token == null) {
      /*
       * Not signed in.
       *
       * Send them to sign-up rather than the session, because the session
       * screen needs an account to register. The alternative — showing the
       * session and then failing at the button — is worse.
       *
       * Note this is a compromise: someone who just wants to read about the
       * session is now looking at a form. The website page they came from
       * already has the full detail and a registration form that needs no
       * account, so the honest answer for a stranger is often "stay on the
       * web" — which is why the manifest only claims /sessions, and why the
       * web form exists at all.
       */
      nav.push(MaterialPageRoute(
        builder: (_) => const AuthScreen(startOnSignUp: true),
      ));
      return;
    }

    nav.push(MaterialPageRoute(
      builder: (_) => SessionDetailScreen(slug: slug),
    ));
  }
}
