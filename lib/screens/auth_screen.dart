import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../theme/mood_stage_theme.dart';

/// Contemplative authentication modal for signing in or syncing with Supabase.
class AuthModal extends StatefulWidget {
  final StagePalette palette;

  const AuthModal({
    super.key,
    required this.palette,
  });

  static Future<void> show(BuildContext context, StagePalette palette) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AuthModal(palette: palette),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  final AuthService _auth = AuthService();
  final CloudSyncService _sync = CloudSyncService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _auth.signUpWithEmail(email: email, password: password);
        if (mounted) {
          setState(() {
            _errorMessage = 'Account created. Please check your email to confirm.';
            _isLoading = false;
          });
        }
      } else {
        await _auth.signInWithEmail(email: email, password: password);
        await _sync.pullFromCloud();
        await _sync.pushToCloud();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome to your sanctuary.',
                style: TextStyle(color: widget.palette.primaryText),
              ),
              backgroundColor: widget.palette.cardSurface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _auth.signOut();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleManualSync() async {
    setState(() => _isLoading = true);
    await _sync.pushToCloud();
    await _sync.pullFromCloud();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sanctuary synchronized.',
            style: TextStyle(color: widget.palette.primaryText),
          ),
          backgroundColor: widget.palette.cardSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final user = _auth.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border(
          top: BorderSide(
            color: palette.cardBorder.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24.0,
        16.0,
        24.0,
        MediaQuery.of(context).viewInsets.bottom + 28.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 38.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: palette.secondaryText.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          const SizedBox(height: 18.0),

          // Header
          Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                size: 22.0,
                color: palette.accent,
              ),
              const SizedBox(width: 8.0),
              Text(
                user != null ? 'Your Sanctuary Account' : 'Cloud Sanctuary',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18.5,
                  fontWeight: FontWeight.w600,
                  color: palette.primaryText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8.0),

          Text(
            user != null
                ? 'Your reflections, saved verses, and mood history are synced to the cloud.'
                : 'Sign in to quietly backup and sync your reflections across all devices.',
            style: TextStyle(
              fontSize: 13.0,
              height: 1.4,
              color: palette.secondaryText,
            ),
          ),

          const SizedBox(height: 20.0),

          if (user != null) ...[
            // Signed in profile card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: palette.bgTop.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: palette.cardBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: palette.accent.withValues(alpha: 0.2),
                    child: Icon(Icons.person_outline_rounded, color: palette.accent),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email ?? 'Sanctuary Member',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: palette.primaryText,
                          ),
                        ),
                        Text(
                          'Cloud Sync Active',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleManualSync,
                    icon: const Icon(Icons.sync_rounded, size: 16.0),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                OutlinedButton(
                  onPressed: _handleSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.secondaryText,
                    side: BorderSide(
                      color: palette.cardBorder.withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ] else ...[
            // Sign in / Sign up form
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: palette.primaryText, fontSize: 14.0),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: palette.secondaryText),
                filled: true,
                fillColor: palette.bgTop.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(
                    color: palette.cardBorder.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),

            const SizedBox(height: 12.0),

            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: palette.primaryText, fontSize: 14.0),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: palette.secondaryText),
                filled: true,
                fillColor: palette.bgTop.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(
                    color: palette.cardBorder.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10.0),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.0,
                ),
              ),
            ],

            const SizedBox(height: 18.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Create Sanctuary Account' : 'Sign In',
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12.0),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = null;
                  });
                },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign In'
                      : 'New here? Create a Sanctuary account',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
