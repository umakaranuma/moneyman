import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  double _result = 0;
  String _operation = '';
  bool _shouldResetDisplay = false;

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _result = 0;
        _operation = '';
        _shouldResetDisplay = false;
      } else if (value == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (value == '=') {
        _calculate();
      } else if (['+', '-', '×', '÷'].contains(value)) {
        if (_operation.isNotEmpty && !_shouldResetDisplay) {
          _calculate();
        }
        _operation = value;
        _result = double.parse(_display);
        _shouldResetDisplay = true;
      } else {
        if (_shouldResetDisplay) {
          _display = value;
          _shouldResetDisplay = false;
        } else {
          if (_display == '0') {
            _display = value;
          } else {
            _display += value;
          }
        }
      }
    });
  }

  void _calculate() {
    if (_operation.isEmpty) return;

    double currentValue = double.parse(_display);
    switch (_operation) {
      case '+':
        _result += currentValue;
        break;
      case '-':
        _result -= currentValue;
        break;
      case '×':
        _result *= currentValue;
        break;
      case '÷':
        if (currentValue != 0) {
          _result /= currentValue;
        }
        break;
    }

    _display = _result % 1 == 0
        ? _result.toInt().toString()
        : _result.toStringAsFixed(2);
    _operation = '';
    _shouldResetDisplay = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          'Calculator',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.surfaceVariant.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_operation.isNotEmpty)
                    Text(
                      '$_result $_operation',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 18,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _display,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Buttons
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: Clear, Backspace, Divide
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('C', AppColors.textMuted, () => _onButtonPressed('C')),
                        const SizedBox(width: 12),
                        _buildButton('⌫', AppColors.textMuted, () => _onButtonPressed('⌫')),
                        const SizedBox(width: 12),
                        _buildButton('÷', AppColors.primary, () => _onButtonPressed('÷')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 2: 7, 8, 9, Multiply
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('7', AppColors.textPrimary, () => _onButtonPressed('7')),
                        const SizedBox(width: 12),
                        _buildButton('8', AppColors.textPrimary, () => _onButtonPressed('8')),
                        const SizedBox(width: 12),
                        _buildButton('9', AppColors.textPrimary, () => _onButtonPressed('9')),
                        const SizedBox(width: 12),
                        _buildButton('×', AppColors.primary, () => _onButtonPressed('×')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 3: 4, 5, 6, Subtract
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('4', AppColors.textPrimary, () => _onButtonPressed('4')),
                        const SizedBox(width: 12),
                        _buildButton('5', AppColors.textPrimary, () => _onButtonPressed('5')),
                        const SizedBox(width: 12),
                        _buildButton('6', AppColors.textPrimary, () => _onButtonPressed('6')),
                        const SizedBox(width: 12),
                        _buildButton('-', AppColors.primary, () => _onButtonPressed('-')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 4: 1, 2, 3, Add
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton('1', AppColors.textPrimary, () => _onButtonPressed('1')),
                        const SizedBox(width: 12),
                        _buildButton('2', AppColors.textPrimary, () => _onButtonPressed('2')),
                        const SizedBox(width: 12),
                        _buildButton('3', AppColors.textPrimary, () => _onButtonPressed('3')),
                        const SizedBox(width: 12),
                        _buildButton('+', AppColors.primary, () => _onButtonPressed('+')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 5: 0, Dot, Equals
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildButton('0', AppColors.textPrimary, () => _onButtonPressed('0')),
                        ),
                        const SizedBox(width: 12),
                        _buildButton('.', AppColors.textPrimary, () => _onButtonPressed('.')),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildButton('=', AppColors.primary, () => _onButtonPressed('='), isEquals: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color textColor, VoidCallback onPressed, {bool isEquals = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: isEquals
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  )
                : null,
            color: isEquals ? null : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: isEquals
                ? null
                : Border.all(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
            boxShadow: isEquals
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: isEquals ? Colors.white : textColor,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

