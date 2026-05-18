import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';

class CalculatorContent extends StatefulWidget {
  const CalculatorContent({super.key});

  @override
  State<CalculatorContent> createState() => _CalculatorContentState();
}

class _CalculatorContentState extends State<CalculatorContent> {
  final _display = ValueNotifier<String>('0');
  String _operand = '';
  double _num1 = 0;
  bool _shouldClear = false;

  @override
  void dispose() {
    _display.dispose();
    super.dispose();
  }

  void _onPressed(String btn) {
    final current = _display.value;
    if (btn == 'C') {
      _operand = '';
      _num1 = 0;
      _shouldClear = false;
      _display.value = '0';
    } else if (btn == '+' || btn == '-' || btn == '*' || btn == '/') {
      _num1 = double.tryParse(current) ?? 0;
      _operand = btn;
      _shouldClear = true;
    } else if (btn == '=') {
      final num2 = double.tryParse(current) ?? 0;
      String result = current;
      if (_operand == '+') result = (_num1 + num2).toString();
      if (_operand == '-') result = (_num1 - num2).toString();
      if (_operand == '*') result = (_num1 * num2).toString();
      if (_operand == '/') result = (_num1 / num2).toString();
      if (result.endsWith('.0')) {
        result = result.substring(0, result.length - 2);
      }
      _operand = '';
      _shouldClear = true;
      _display.value = result;
    } else {
      if (current == '0' || _shouldClear) {
        _shouldClear = false;
        _display.value = btn;
      } else {
        _display.value = current + btn;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Column(
        children: [
          // Display — only this rebuilds on button press.
          ValueListenableBuilder<String>(
            valueListenable: _display,
            builder:
                (context, value, _) => RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.spacingMd),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      border: Border.all(color: AppTheme.surface),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.spaceMono(
                        fontSize: AppSizes.calculatorDisplayFontSize,
                        color: AppTheme.text,
                      ),
                    ),
                  ),
                ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          // Button grid — const, never rebuilt.
          Expanded(
            child: RepaintBoundary(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _CalcButton(label: '7', onTap: _onPressed),
                        _CalcButton(label: '8', onTap: _onPressed),
                        _CalcButton(label: '9', onTap: _onPressed),
                        _CalcButton(
                          label: '/',
                          color: AppTheme.blue.withValues(alpha: 0.2),
                          onTap: _onPressed,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _CalcButton(label: '4', onTap: _onPressed),
                        _CalcButton(label: '5', onTap: _onPressed),
                        _CalcButton(label: '6', onTap: _onPressed),
                        _CalcButton(
                          label: '*',
                          color: AppTheme.blue.withValues(alpha: 0.2),
                          onTap: _onPressed,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _CalcButton(label: '1', onTap: _onPressed),
                        _CalcButton(label: '2', onTap: _onPressed),
                        _CalcButton(label: '3', onTap: _onPressed),
                        _CalcButton(
                          label: '-',
                          color: AppTheme.blue.withValues(alpha: 0.2),
                          onTap: _onPressed,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _CalcButton(
                          label: 'C',
                          color: AppTheme.red.withValues(alpha: 0.2),
                          onTap: _onPressed,
                        ),
                        _CalcButton(label: '0', onTap: _onPressed),
                        _CalcButton(
                          label: '=',
                          color: AppTheme.green.withValues(alpha: 0.2),
                          onTap: _onPressed,
                        ),
                        _CalcButton(
                          label: '+',
                          color: AppTheme.blue.withValues(alpha: 0.2),
                          onTap: _onPressed,
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
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.onTap,
    this.color = AppTheme.surface0,
  });

  final String label;
  final Color color;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXxs),
        child: InkWell(
          onTap: () => onTap(label),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
}
