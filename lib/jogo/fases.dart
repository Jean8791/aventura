import 'package:flutter/material.dart';

class DadosDaFase {
  const DadosDaFase({
    required this.nome,
    required this.arquivo,
    required this.fundo,
    required this.ceu,
    required this.icone,
    required this.cor,
    this.musica = 'musica_fase1.wav',
    this.tilePlataforma = 1,
    this.chefe = false,
  });

  final String nome;
  final String arquivo;
  final String fundo;
  final Color ceu;
  final IconData icone;
  final Color cor;
  final String musica;
  final int tilePlataforma;
  final bool chefe;
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
  DadosDaFase(
    nome: 'Caverna de Cristal',
    arquivo: 'fase4.tmx',
    fundo: 'fundo_caverna.png',
    ceu: Color(0xFF251F3D),
    icone: Icons.diamond_rounded,
    cor: Color(0xFFB794F6),
    tilePlataforma: 141,
  ),
  DadosDaFase(
    nome: 'Covil do Feiticeiro',
    arquivo: 'fase5.tmx',
    fundo: 'fundo_caverna.png',
    ceu: Color(0xFF1A1530),
    icone: Icons.auto_fix_high_rounded,
    cor: Color(0xFFFF4FD8),
    musica: 'musica_chefe.wav',
    tilePlataforma: 141,
    chefe: true,
  ),
];
