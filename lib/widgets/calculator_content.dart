import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class CalculatorContent extends StatefulWidget {
  const CalculatorContent({super.key});

  @override
  State<CalculatorContent> createState() => _CalculatorContentState();
}

class _CalculatorContentState extends State<CalculatorContent> {
  String _display = '0';
  String _operand = '';
  double _num1 = 0;
  bool _shouldClear = false;

  void _onPressed(String btn) {
    setState(() {
      if (btn == 'C') {
        _display = '0';
        _operand = '';
        _num1 = 0;
      } else if (btn == '+' || btn == '-' || btn == '*' || btn == '/') {
        _num1 = double.tryParse(_display) ?? 0;
        _operand = btn;
        _shouldClear = true;
      } else if (btn == '=') {
        final num2 = double.tryParse(_display) ?? 0;
        if (_operand == '+') _display = (_num1 + num2).toString();
        if (_operand == '-') _display = (_num1 - num2).toString();
        if (_operand == '*') _display = (_num1 * num2).toString();
        if (_operand == '/') _display = (_num1 / num2).toString();
        if (_display.endsWith('.0')) {
          _display = _display.substring(0, _display.length - 2);
        }
        _operand = '';
        _shouldClear = true;
      } else {
        if (_display == '0' || _shouldClear) {
          _display = btn;
          _shouldClear = false;
        } else {
          _display += btn;
        }
      }
    });
  }

  Widget _buildBtn(String label, {Color color = AppTheme.surface0}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: InkWell(
          onTap: () => _onPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.surface),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border.all(color: AppTheme.surface),
            ),
            child: Text(
              _display,
              style: GoogleFonts.spaceMono(fontSize: 24, color: AppTheme.text),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildBtn('7'),
                      _buildBtn('8'),
                      _buildBtn('9'),
                      _buildBtn(
                        '/',
                        color: AppTheme.blue.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildBtn('4'),
                      _buildBtn('5'),
                      _buildBtn('6'),
                      _buildBtn(
                        '*',
                        color: AppTheme.blue.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildBtn('1'),
                      _buildBtn('2'),
                      _buildBtn('3'),
                      _buildBtn(
                        '-',
                        color: AppTheme.blue.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildBtn(
                        'C',
                        color: AppTheme.red.withValues(alpha: 0.2),
                      ),
                      _buildBtn('0'),
                      _buildBtn(
                        '=',
                        color: AppTheme.green.withValues(alpha: 0.2),
                      ),
                      _buildBtn(
                        '+',
                        color: AppTheme.blue.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
