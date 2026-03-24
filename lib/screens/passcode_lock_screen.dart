import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PasscodeLockScreen extends StatefulWidget {
  final String expectedPin;
  final VoidCallback? onUnlocked;
  final bool popOnSuccess;
  final String title;
  final String? subtitle;

  const PasscodeLockScreen({
    super.key,
    required this.expectedPin,
    this.onUnlocked,
    this.popOnSuccess = false,
    this.title = 'Enter your passcode',
    this.subtitle,
  });

  @override
  State<PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<PasscodeLockScreen> {
  String _input = '';
  bool _isValidating = false;
  String? _errorText;

  void _onDigitTap(String digit) {
    if (_isValidating || _input.length >= 4) return;
    setState(() {
      _errorText = null;
      _input += digit;
    });
    if (_input.length == 4) {
      _validatePin();
    }
  }

  void _onBackspaceTap() {
    if (_isValidating || _input.isEmpty) return;
    setState(() {
      _errorText = null;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _validatePin() async {
    setState(() => _isValidating = true);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    if (_input == widget.expectedPin) {
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      }
      widget.onUnlocked?.call();
      return;
    }

    setState(() {
      _input = '';
      _isValidating = false;
      _errorText = 'Incorrect passcode. Try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              Icons.lock_rounded,
              size: 56,
              color: AppColors.textPrimary.withValues(alpha: 0.95),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _input.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.textPrimary : Colors.transparent,
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.9),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: Text(
                _errorText ?? '',
                style: GoogleFonts.inter(
                  color: AppColors.expense,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(flex: 2),
            _buildKeyboard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        _keypadRow(['1', '2', '3']),
        const SizedBox(height: 18),
        _keypadRow(['4', '5', '6']),
        const SizedBox(height: 18),
        _keypadRow(['7', '8', '9']),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 90, height: 60),
            _keyButton('0', onTap: () => _onDigitTap('0')),
            _iconKeyButton(
              icon: Icons.backspace_outlined,
              onTap: _onBackspaceTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map((key) => _keyButton(key, onTap: () => _onDigitTap(key)))
          .toList(),
    );
  }

  Widget _keyButton(String label, {required VoidCallback onTap}) {
    return SizedBox(
      width: 90,
      height: 60,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w400,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _iconKeyButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 90,
      height: 60,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }
}
