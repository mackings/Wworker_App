import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';


class CustomOTP extends StatefulWidget {
  final int length;
  final void Function(String)? onCompleted;
  final VoidCallback? onResend;
  final bool showFromMessages;
  final String? fromMessageCode; // e.g. "523432"
  final Duration resendDuration;

  const CustomOTP({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onResend,
    this.showFromMessages = true,
    this.fromMessageCode,
    this.resendDuration = const Duration(seconds: 30),
  });

  @override
  State<CustomOTP> createState() => _CustomOTPState();
}

class _CustomOTPState extends State<CustomOTP> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  Timer? _timer;
  late Duration _remaining;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    _remaining = widget.resendDuration;
    _startTimer();
    // focus first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nodes.isNotEmpty) _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.resendDuration;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining.inSeconds <= 1) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _remaining = Duration(seconds: _remaining.inSeconds - 1));
      }
    });
  }

  void _onBoxChanged(String value, int i) {
    if (value.isNotEmpty) {
      // keep only first char
      if (value.length > 1) {
        _controllers[i].text = value.substring(value.length - 1);
      }
      if (i + 1 < widget.length) _nodes[i + 1].requestFocus();
    } else {
      if (i - 1 >= 0) _nodes[i - 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    widget.onCompleted?.call(otp);
  }

  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_nodes.isNotEmpty) _nodes[0].requestFocus();
    setState(() {});
  }

  void _fillFromMessage(String code) {
    final chars = code.split('');
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }
    if (widget.length > 0) _nodes.last.requestFocus();
    final otp = _controllers.map((c) => c.text).join();
    widget.onCompleted?.call(otp);
    setState(() {});
  }

  void _onKeypadTap(String key) {
    // find first empty
    for (int i = 0; i < widget.length; i++) {
      if (_controllers[i].text.isEmpty) {
        _controllers[i].text = key;
        _nodes[i].requestFocus();
        if (i + 1 < widget.length) _nodes[i + 1].requestFocus();
        break;
      }
    }
    final otp = _controllers.map((c) => c.text).join();
    widget.onCompleted?.call(otp);
    setState(() {});
  }

  void _onKeypadBackspace() {
    // find last filled
    for (int i = widget.length - 1; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        _controllers[i].clear();
        _nodes[i].requestFocus();
        break;
      }
    }
    setState(() {});
  }

Widget _buildBox(int index) {
  final bool isFilled = _controllers[index].text.isNotEmpty;
  final bool isFocused = _nodes[index].hasFocus;

  return GestureDetector(
    onTap: () {
      FocusScope.of(context).requestFocus(_nodes[index]);
    },
    onLongPress: () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final pasted = data?.text ?? '';
      if (pasted.isNotEmpty) {
        final digits = pasted.replaceAll(RegExp(r'\D'), '');
        if (digits.isNotEmpty) _fillFromMessage(digits);
      }
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 52,
      height: 52,
      decoration: ShapeDecoration(
        color: const Color(0xFFF5F8F2),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: isFocused
                ? const Color(0xFFA16438)
                : (isFilled ? const Color(0xFF8A8A8A) : const Color(0xFFD3D3D3)),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        shadows: isFocused
            ? [
                const BoxShadow(
                  color: Color(0x1AA16438),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _nodes[index],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: isFilled ? const Color(0xFF302E2E) : const Color(0xFF7B7B7B),
            height: 1.2,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => _onBoxChanged(v, index),
          onTap: () {
            FocusScope.of(context).requestFocus(_nodes[index]);
          },
        ),
      ),
    ),
  );
}


Widget _buildBoxesRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(
      widget.length,
      (i) => Padding(
        padding: const EdgeInsets.all(2),
        child: _buildBox(i),
      ),
    ),
  );
}


  Widget _buildTimerRow() {
    final timerText = _canResend ? '00:00' : '${_remaining.inSeconds} secs';
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            timerText,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF302E2E),
            ),
          ),
          GestureDetector(
            onTap: _canResend
                ? () {
                    widget.onResend?.call();
                    _startTimer();
                    _clearAll();
                  }
                : null,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _canResend ? const Color(0xFF302E2E) : const Color(0xFFB0B0B0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromMessagesCard() {
    final code = widget.fromMessageCode ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
   
      ),
      child: Column(
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 44, height: 44),
              Opacity(
                opacity: 0.10,
                child: Container(width: 1, height: 25, color: const Color(0xFF212020)),
              ),
              SizedBox(
                width: 285,
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212020),
                      ),
                    ),
                    Text(
                      code,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF212020),
                      ),
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: 0.10,
                child: Container(width: 1, height: 25, color: const Color(0xFF212020)),
              ),
              const SizedBox(width: 44, height: 44),
            ],
          ),

          // keypad grid (3 columns x 4 rows like your frame)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 12),
                _buildKeypadRow(['', '0', '⌫']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypadButton(String label, {VoidCallback? onTap}) {
    final bool isBack = label == '⌫';
    final bool isEmpty = label.isEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: isEmpty ? null : onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: ShapeDecoration(
            color: const Color(0xFFF5F8F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            shadows: const [
              BoxShadow(color: Color(0x7F000000), blurRadius: 0, offset: Offset(0, 1))
            ],
          ),
          child: Center(
            child: isBack
                ? const Icon(Icons.clear, color: Color(0xFF302E2E))
                : Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: const Color(0xFF302E2E)),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((v) {
        if (v == '⌫') {
          return _keypadButton(v, onTap: _onKeypadBackspace);
        } else if (v.isEmpty) {
          return Expanded(child: Container());
        } else {
          return _keypadButton(v, onTap: () => _onKeypadTap(v));
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBoxesRow(),
              const SizedBox(height: 12),
              _buildTimerRow(),
            ],
          ),
        ),

        const SizedBox(height: 16),
        if (widget.showFromMessages)
          _buildFromMessagesCard(),
      ],
    );
  }
}
