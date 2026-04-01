import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';


class CalculatorScreen extends StatefulWidget {
  final String? initialValue;
  
  const CalculatorScreen({super.key, this.initialValue});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late String _display;
  double _result = 0;
  String _operation = '';
  bool _shouldResetDisplay = false;
  String? _pressedButton;

  @override
  void initState() {
    super.initState();
    // Initialize display with initial value or '0'
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      // Remove currency symbols and parse the value
      String cleanValue = widget.initialValue!
          .replaceAll(RegExp(r'[^\d.]'), '')
          .trim();
      try {
        double parsedValue = double.parse(cleanValue);
        _display = parsedValue % 1 == 0
            ? parsedValue.toInt().toString()
            : parsedValue.toStringAsFixed(2);
      } catch (e) {
        _display = '0';
      }
    } else {
      _display = '0';
    }
  }

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
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Return the current display value when going back
                      Navigator.pop(context, _display);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Calculator',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Display Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surface,
                      AppColors.surfaceVariant.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_operation.isNotEmpty)
                      AnimatedOpacity(
                        opacity: _operation.isNotEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_result $_operation',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                       Helpers.formatCurrency(double.tryParse(_display) ?? 0),
                    style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 64,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -2,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons Section
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Row 1: Clear, Backspace, Divide
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildButton('C', AppColors.textMuted, () => _onButtonPressed('C'), isOperator: true),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildButton('⌫', AppColors.textMuted, () => _onButtonPressed('⌫'), isOperator: true),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildButton('÷', AppColors.primary, () => _onButtonPressed('÷'), isOperator: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Row 2: 7, 8, 9, Multiply
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildButton('7', AppColors.textPrimary, () => _onButtonPressed('7'))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('8', AppColors.textPrimary, () => _onButtonPressed('8'))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('9', AppColors.textPrimary, () => _onButtonPressed('9'))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildButton('×', AppColors.primary, () => _onButtonPressed('×'), isOperator: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Row 3: 4, 5, 6, Subtract
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildButton('4', AppColors.textPrimary, () => _onButtonPressed('4'))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('5', AppColors.textPrimary, () => _onButtonPressed('5'))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('6', AppColors.textPrimary, () => _onButtonPressed('6'))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildButton('-', AppColors.primary, () => _onButtonPressed('-'), isOperator: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Row 4: 1, 2, 3, Add
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildButton('1', AppColors.textPrimary, () => _onButtonPressed('1'))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('2', AppColors.textPrimary, () => _onButtonPressed('2'))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('3', AppColors.textPrimary, () => _onButtonPressed('3'))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildButton('+', AppColors.primary, () => _onButtonPressed('+'), isOperator: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Row 5: 0, Dot, Equals
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildButton('0', AppColors.textPrimary, () => _onButtonPressed('0')),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButton('.', AppColors.textPrimary, () => _onButtonPressed('.'))),
                          const SizedBox(width: 14),
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
      ),
    );
  }

  Widget _buildButton(String text, Color textColor, VoidCallback onPressed, {bool isEquals = false, bool isOperator = false}) {
    final bool isPressed = _pressedButton == text;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressedButton = text;
        });
        onPressed();
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _pressedButton = null;
            });
          }
        });
      },
      onTapCancel: () {
        setState(() {
          _pressedButton = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        // ignore: deprecated_member_use
        transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          gradient: isEquals
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                )
              : isOperator && !isEquals
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceVariant,
                        AppColors.surfaceVariant.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
          color: isEquals || isOperator
              ? null
              : AppColors.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: isEquals
              ? null
              : Border.all(
                  color: isOperator
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceVariant.withValues(alpha: 0.3),
                  width: 1.5,
                ),
          boxShadow: isEquals
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      if (isOperator)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 0),
                        ),
                    ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isEquals
                  ? Colors.white
                  : isOperator
                      ? AppColors.primary
                      : textColor,
              fontSize: 28,
              fontWeight: isEquals ? FontWeight.w500 : FontWeight.w400,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}

