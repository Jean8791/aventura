import 'package:flutter/material.dart';

enum Golpe { espada, raio, fogo, terra, agua, pisao }

class ClasseDeHeroi {
  const ClasseDeHeroi({
    required this.nome,
    required this.imagem,
    required this.poder,
    required this.nomeDoPoder,
    required this.icone,
    required this.cor,
    required this.coracoes,
    required this.recarga,
  });

  final String nome;
  final String imagem;
  final Golpe poder;
  final String nomeDoPoder;
  final IconData icone;
  final Color cor;
  final int coracoes;
  final double recarga;

  String get caminhoDaImagem => 'assets/images/$imagem';
}

const classes = [
  ClasseDeHeroi(
    nome: 'Guerreiro',
    imagem: 'herois/guerreiro.png',
    poder: Golpe.espada,
    nomeDoPoder: 'Espadada',
    icone: Icons.shield_rounded,
    cor: Color(0xFFB8C4D6),
    coracoes: 4,
    recarga: 0.35,
  ),
  ClasseDeHeroi(
    nome: 'Mago do Raio',
    imagem: 'herois/mago_raio.png',
    poder: Golpe.raio,
    nomeDoPoder: 'Raio',
    icone: Icons.bolt_rounded,
    cor: Color(0xFFFFE066),
    coracoes: 3,
    recarga: 0.5,
  ),
  ClasseDeHeroi(
    nome: 'Mago do Fogo',
    imagem: 'herois/mago_fogo.png',
    poder: Golpe.fogo,
    nomeDoPoder: 'Bola de fogo',
    icone: Icons.local_fire_department_rounded,
    cor: Color(0xFFFF6B4A),
    coracoes: 3,
    recarga: 0.45,
  ),
  ClasseDeHeroi(
    nome: 'Maga da Terra',
    imagem: 'herois/maga_terra.png',
    poder: Golpe.terra,
    nomeDoPoder: 'Bloco de pedra',
    icone: Icons.terrain_rounded,
    cor: Color(0xFF7CC35A),
    coracoes: 3,
    recarga: 0.5,
  ),
  ClasseDeHeroi(
    nome: 'Maga da Água',
    imagem: 'herois/maga_agua.png',
    poder: Golpe.agua,
    nomeDoPoder: 'Bolha',
    icone: Icons.water_drop_rounded,
    cor: Color(0xFF5FB7FF),
    coracoes: 3,
    recarga: 0.55,
  ),
];
