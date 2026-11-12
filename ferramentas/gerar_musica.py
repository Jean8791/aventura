#!/usr/bin/env python3
"""Compõe e gera as músicas de fundo em assets/audio/.

Músicas originais em estilo 8-bit: melodia em onda quadrada, baixo em onda triangular e
bateria de ruído, com 16 compassos que repetem sem emenda.
  musica_fase1.wav  Dó maior, 150 BPM, alegre (não usada mais; base da música dos créditos)
  musica_chefe.wav  Lá menor, 168 BPM (não gerada mais: o chefe usa música orquestral)
  musica_creditos.wav  reprise da fase 1, 110 BPM, mais calma, para os créditos

Notação das partes: cada compasso tem 8 colcheias separadas por espaço.
  C5, F#4, Bb3  nota (nome + oitava)
  -             continua a nota anterior
  .             pausa
"""

import math
import struct
import wave
from pathlib import Path

TAXA = 22050

MELODIA = [
    "E5 . G5 . C6 - G5 .",
    "A5 - G5 E5 C5 - E5 .",
    "F5 . A5 . C6 - A5 .",
    "G5 - F5 D5 B4 - D5 .",
    "E5 . G5 . C6 - E6 .",
    "D6 - C6 A5 E5 - A5 .",
    "F5 A5 C6 A5 G5 F5 E5 D5",
    "G5 - - . D5 E5 F5 G5",
    "A5 - A5 G5 A5 - C6 -",
    "B5 - G5 . D5 - G5 .",
    "G5 - G5 F5 E5 - B4 .",
    "C5 - E5 . A5 - - .",
    "A5 . C6 . F6 - C6 .",
    "B5 . D6 . G6 - D6 .",
    "E6 - D6 C6 G5 - E5 .",
    "D5 . G5 . B5 . D6 .",
]

ACORDES = ["C", "Am", "F", "G", "C", "Am", "F", "G", "F", "G", "Em", "Am", "F", "G", "C", "G"]

MELODIA_CHEFE = [
    "A4 . C5 . E5 - D5 C5",
    "B4 - C5 - A4 - - .",
    "F5 . E5 . C5 - A4 .",
    "G4 - B4 - D5 - - .",
    "A5 . G5 . E5 - C5 E5",
    "D5 - C5 - A4 - E4 .",
    "F4 A4 C5 F5 E5 - C5 .",
    "G#4 - B4 - E5 - - .",
    "D5 . F5 . A5 - F5 .",
    "E5 - C5 - A4 - - .",
    "D5 F5 A5 F5 D5 - F5 .",
    "E5 - G#4 - B4 - - .",
    "C6 . A5 . F5 - A5 .",
    "B5 . G5 . D5 - G5 .",
    "A5 - E5 - C5 - A4 .",
    "G#4 . B4 . E5 . G#5 .",
]

ACORDES_CHEFE = ["Am", "Am", "F", "G", "Am", "Am", "F", "E", "Dm", "Am", "Dm", "E", "F", "G", "Am", "E"]

TONICA_E_QUINTA = {
    "Dm": ("D3", "A2"),
    "E": ("E2", "B2"),
    "C": ("C3", "G2"),
    "Am": ("A2", "E2"),
    "F": ("F2", "C3"),
    "G": ("G2", "D3"),
    "Em": ("E2", "B2"),
}

SEMITONS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def frequencia(nota):
    nome, resto = nota[0], nota[1:]
    acidente = 0
    if resto and resto[0] in "#b":
        acidente = 1 if resto[0] == "#" else -1
        resto = resto[1:]
    midi = 12 * (int(resto) + 1) + SEMITONS[nome] + acidente
    return 440.0 * 2 ** ((midi - 69) / 12)


def ler_parte(compassos):
    notas = []
    passo = 0
    for compasso in compassos:
        for simbolo in compasso.split():
            if simbolo == "-":
                if notas:
                    notas[-1][2] += 1
            elif simbolo != ".":
                notas.append([frequencia(simbolo), passo, 1])
            passo += 1
    return notas


def baixo(acordes, padrao):
    compassos = []
    for acorde in acordes:
        tonica, quinta = TONICA_E_QUINTA[acorde]
        compassos.append(padrao.format(t=tonica, q=quinta))
    return compassos


def envelope(t, duracao, ataque=0.005, soltura=0.03):
    if t < ataque:
        return t / ataque
    if t > duracao - soltura:
        return max(0.0, (duracao - t) / soltura)
    return 1.0


def onda_quadrada(fase, ciclo=0.25):
    return 1.0 if (fase % 1.0) < ciclo else -1.0


def onda_triangular(fase):
    x = fase % 1.0
    return 4 * x - 1 if x < 0.5 else 3 - 4 * x


class Ruido:
    def __init__(self, semente=12345):
        self.estado = semente

    def proximo(self):
        self.estado = (1103515245 * self.estado + 12345) & 0x7FFFFFFF
        return self.estado / 0x3FFFFFFF - 1.0


def tocar_notas(saida, notas, onda, volume, colcheia, decaimento=0.0):
    for freq, passo, colcheias in notas:
        inicio = int(passo * colcheia * TAXA)
        duracao = colcheias * colcheia * 0.95
        n = int(duracao * TAXA)
        for i in range(n):
            t = i / TAXA
            amp = volume * envelope(t, duracao) * (math.exp(-t * decaimento) * 0.4 + 0.6 if decaimento else 1)
            if inicio + i < len(saida):
                saida[inicio + i] += amp * onda(freq * t)


def bateria(saida, compassos, colcheia, bumbos=(0, 4)):
    ruido = Ruido()
    amostras_colcheia = colcheia * TAXA
    for passo in range(compassos * 8):
        inicio = int(passo * amostras_colcheia)
        no_compasso = passo % 8
        if no_compasso in bumbos:
            for i in range(int(0.12 * TAXA)):
                t = i / TAXA
                freq = 50 + 70 * math.exp(-t * 30)
                saida[inicio + i] += 0.45 * math.exp(-t * 25) * math.sin(2 * math.pi * freq * t)
        if no_compasso in (2, 6):
            for i in range(int(0.12 * TAXA)):
                t = i / TAXA
                saida[inicio + i] += 0.12 * math.exp(-t * 30) * ruido.proximo()
        for i in range(int(0.03 * TAXA)):
            t = i / TAXA
            saida[inicio + i] += 0.035 * math.exp(-t * 120) * ruido.proximo()


def compor(nome, melodia, acordes, bpm, padrao_do_baixo, bumbos):
    colcheia = 60 / bpm / 2
    compassos = len(melodia)
    total = int(compassos * 8 * colcheia * TAXA)
    saida = [0.0] * total

    tocar_notas(saida, ler_parte(melodia), lambda f: onda_quadrada(f), 0.16, colcheia, decaimento=6)
    tocar_notas(saida, ler_parte(baixo(acordes, padrao_do_baixo)), onda_triangular, 0.30, colcheia)
    bateria(saida, compassos, colcheia, bumbos)

    destino = Path(__file__).resolve().parent.parent / "assets" / "audio" / nome
    with wave.open(str(destino), "wb") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(TAXA)
        quadros = bytearray()
        for valor in saida:
            quadros += struct.pack("<h", int(max(-1.0, min(1.0, valor)) * 32000))
        arquivo.writeframes(bytes(quadros))
    print(f"{destino.name}: {total / TAXA:.1f} s, pico {max(abs(v) for v in saida):.2f}")


def main():
    # As fases e o chefe usam músicas orquestrais do OpenGameArt (ver assets/CREDITOS-AUDIO.md).
    # Para regerar as antigas em 8-bit: musica_fase1.wav (150 BPM) e musica_chefe.wav (168 BPM).
    compor("musica_creditos.wav", MELODIA, ACORDES, 110, "{t} . . . {q} . . .", (0,))


if __name__ == "__main__":
    main()
