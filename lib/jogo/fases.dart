import 'package:flutter/material.dart';

class DadosDaFase {
  const DadosDaFase({
    required this.nome,
    required this.arquivo,
    required this.fundo,
    required this.ceu,
    required this.icone,
    required this.cor,
  });

  final String nome;
  final String arquivo;
  final String fundo;
  final Color ceu;
  final IconData icone;
  final Color cor;
}

const fases = [
  DadosDaFase(
    nome: 'Floresta',
    arquivo: 'fase1.tmx',
    fundo: 'fundo.png',
    ceu: Color(0xFFDFF6F5),
    icone: Icons.park_rounded,
    cor: Color(0xFF7CC35A),
  ),
  DadosDaFase(
    nome: 'Montanha Gelada',
    arquivo: 'fase2.tmx',
    fundo: 'fundo.png',
    ceu: Color(0xFFEAF4FF),
    icone: Icons.ac_unit_rounded,
    cor: Color(0xFF8FD3FF),
  ),
  DadosDaFase(
    nome: 'Deserto de Fogo',
    arquivo: 'fase3.tmx',
    fundo: 'fundo_deserto.png',
    ceu: Color(0xFFFBC97B),
    icone: Icons.local_fire_department_rounded,
    cor: Color(0xFFFF8A3D),
  ),
];
