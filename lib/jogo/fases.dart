import 'package:flutter/material.dart';

class DadosDaFase {
  const DadosDaFase({
    required this.nome,
    required this.arquivo,
    required this.fundo,
    required this.ceu,
    required this.icone,
    required this.cor,
    required this.musica,
    required this.ambiente,
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

  /// Som de fundo que toca no lugar da música quando ela está desligada.
  final String ambiente;
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
    musica: 'musica_floresta.ogg',
    ambiente: 'ambiente_floresta.mp3',
  ),
  DadosDaFase(
    nome: 'Montanha Gelada',
    arquivo: 'fase2.tmx',
    fundo: 'fundo.png',
    ceu: Color(0xFFEAF4FF),
    icone: Icons.ac_unit_rounded,
    cor: Color(0xFF8FD3FF),
    musica: 'musica_gelo.ogg',
    ambiente: 'ambiente_gelo.ogg',
  ),
  DadosDaFase(
    nome: 'Deserto de Fogo',
    arquivo: 'fase3.tmx',
    fundo: 'fundo_deserto.png',
    ceu: Color(0xFFFBC97B),
    icone: Icons.local_fire_department_rounded,
    cor: Color(0xFFFF8A3D),
    musica: 'musica_deserto.wav',
    ambiente: 'ambiente_deserto.wav',
  ),
  DadosDaFase(
    nome: 'Caverna de Cristal',
    arquivo: 'fase4.tmx',
    fundo: 'fundo_caverna.png',
    ceu: Color(0xFF251F3D),
    icone: Icons.diamond_rounded,
    cor: Color(0xFFB794F6),
    musica: 'musica_caverna.mp3',
    ambiente: 'ambiente_caverna.ogg',
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
    ambiente: 'ambiente_covil.ogg',
    tilePlataforma: 141,
    chefe: true,
  ),
];
