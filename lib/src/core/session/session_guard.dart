import 'package:flutter/material.dart';

import 'session_manager.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({
    required this.sessionManager,
    required this.redirectRoute,
    required this.child,
    super.key,
  });

  final SessionManager sessionManager;
  final String redirectRoute;
  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  @override
  void initState() {
    super.initState();
    widget.sessionManager.addListener(_handleSessionChanged);
  }

  @override
  void didUpdateWidget(covariant SessionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionManager == widget.sessionManager) {
      return;
    }

    oldWidget.sessionManager.removeListener(_handleSessionChanged);
    widget.sessionManager.addListener(_handleSessionChanged);
  }

  @override
  void dispose() {
    widget.sessionManager.removeListener(_handleSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.sessionManager.isAuthenticated) {
      _redirectToLogin();
      return const SizedBox.shrink();
    }

    return widget.child;
  }

  void _handleSessionChanged() {
    if (!mounted || widget.sessionManager.isAuthenticated) {
      return;
    }

    _redirectToLogin();
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.redirectRoute,
        (route) => false,
      );
    });
  }
}
