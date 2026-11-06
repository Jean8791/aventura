import 'package:flutter/material.dart';

class BotaoGrande extends StatefulWidget {
  const BotaoGrande({
    super.key,
    required this.aoApertar,
    required this.child,
    this.autofocus = false,
    this.cor = const Color(0xFFFFC93C),
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
  });

  final VoidCallback aoApertar;
  final Widget child;
  final bool autofocus;
  final Color cor;
  final EdgeInsets padding;

  @override
  State<BotaoGrande> createState() => _BotaoGrandeState();
}

class _BotaoGrandeState extends State<BotaoGrande> {
  bool _focado = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _focado ? 1.08 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: widget.cor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _focado ? const Color(0xFFFF7A1A) : const Color(0xFF3B2B4F),
            width: _focado ? 6 : 3,
          ),
        ),
        elevation: _focado ? 10 : 4,
        child: InkWell(
          autofocus: widget.autofocus,
          borderRadius: BorderRadius.circular(20),
          onFocusChange: (focado) => setState(() => _focado = focado),
          onTap: widget.aoApertar,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

const estiloTitulo = TextStyle(
  fontSize: 40,
  fontWeight: FontWeight.w900,
  color: Colors.white,
  shadows: [Shadow(offset: Offset(3, 3), color: Color(0xFF3B2B4F))],
);

const estiloBotao = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w800,
  color: Color(0xFF3B2B4F),
);
