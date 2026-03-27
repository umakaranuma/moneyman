import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PasscodeSetupScreen extends StatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  State<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends State<PasscodeSetupScreen> {
  String _input = '';
  String? _firstPin;
  String? _errorText;
  bool _isProcessing = false;

  bool get _isConfirmStep => _firstPin != null;

  void _onDigitTap(String digit) {
    if (_isProcessing || _input.length >= 4) return;
    setState(() {
      _errorText = null;
      _input += digit;
    });
    if (_input.length == 4) {
      _onCompleteEntry();
    }
  }

  void _onBackspaceTap() {
    if (_isProcessing || _input.isEmpty) return;
    setState(() {
      _errorText = null;
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _onCompleteEntry() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    if (_firstPin == null) {
      setState(() {
        _firstPin = _input;
        _input = '';
        _isProcessing = false;
      });
      return;
    }

    if (_input == _firstPin) {
      Navigator.of(context).pop(_input);
      return;
    }

    setState(() {
      _errorText = 'Passcodes do not match. Try again.';
      _firstPin = null;
      _input = '';
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Passcode Lock',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
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
              _isConfirmStep ? 'Confirm passcode' : 'Set your passcode',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirmStep
                  ? 'Re-enter the same 4-digit passcode'
                  : 'Enter a new 4-digit passcode',
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
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
