#!/usr/bin/env python3
"""Sintetiza os efeitos sonoros do herói (pulo, dano e poderes) em WAV mono.

Sons originais em estilo 8-bit, feitos só com Python puro (sem dependências):
osciladores, ruído filtrado, envelopes e varreduras de tom.

Uso:
  python3 ferramentas/gerar_sons.py                gera as versões escolhidas em assets/audio/
  python3 ferramentas/gerar_sons.py --previa DIR   gera as versões a/b de cada som em DIR
"""

import argparse
import math
import random
import struct
import wave
from pathlib import Path

TAXA = 22050


# ---------- blocos básicos ----------

def amostras(duracao):
    return int(duracao * TAXA)


def envelope(i, total, ataque=0.005, soltura=0.05, curva=1.0):
    """Ataque linear, decaimento até zero com a curva dada e soltura suave no fim."""
    t = i / TAXA
    dur = total / TAXA
    if t < ataque:
        return t / ataque
    resto = 1 - (t - ataque) / max(1e-6, dur - ataque)
    valor = max(0.0, resto) ** curva
    if dur - t < soltura:
        valor *= max(0.0, (dur - t) / soltura)
    return valor


def varredura(f0, f1, i, total, expo=True):
    p = i / max(1, total - 1)
    if expo:
        return f0 * (f1 / f0) ** p
    return f0 + (f1 - f0) * p


class Oscilador:
    def __init__(self):
        self.fase = 0.0

    def avancar(self, freq):
        self.fase = (self.fase + freq / TAXA) % 1.0
        return self.fase

    def quadrada(self, freq, ciclo=0.5):
        return 1.0 if self.avancar(freq) < ciclo else -1.0

    def triangular(self, freq):
        f = self.avancar(freq)
        return 4 * f - 1 if f < 0.5 else 3 - 4 * f

    def seno(self, freq):
        return math.sin(2 * math.pi * self.avancar(freq))


class PassaBaixa:
    def __init__(self):
        self.y = 0.0

    def __call__(self, x, corte):
        a = 1 - math.exp(-2 * math.pi * corte / TAXA)
        self.y += a * (x - self.y)
        return self.y


class PassaFaixa:
    """Duas passa-baixas em cascata menos uma mais grave: faixa em torno do corte."""

    def __init__(self):
        self.alta = PassaBaixa()
        self.baixa = PassaBaixa()

    def __call__(self, x, centro):
        return self.alta(x, centro * 1.6) - self.baixa(x, centro * 0.6)


def ruido(rng):
    return rng.uniform(-1, 1)


def misturar(*faixas):
    total = max(len(f) for f in faixas)
    saida = [0.0] * total
    for f in faixas:
        for i, v in enumerate(f):
            saida[i] += v
    return saida


def normalizar(sinal, pico=0.8):
    maior = max(abs(v) for v in sinal) or 1.0
    return [v * pico / maior for v in sinal]


def salvar(sinal, destino):
    sinal = normalizar(sinal)
    with wave.open(str(destino), "wb") as arquivo:
        arquivo.setnchannels(1)
        arquivo.setsampwidth(2)
        arquivo.setframerate(TAXA)
        arquivo.writeframes(b"".join(struct.pack("<h", int(v * 32000)) for v in sinal))
    print(f"{destino.name}: {len(sinal) / TAXA:.2f} s")


# ---------- pulo ----------

def pulo_a():
    """Pulinho 8-bit: quadrada fina subindo rápido."""
    n, osc = amostras(0.16), Oscilador()
    return [0.5 * osc.quadrada(varredura(320, 760, i, n), 0.25) * envelope(i, n, soltura=0.04)
            for i in range(n)]


def pulo_b():
    """Boing macio: triangular subindo com um tremidinho."""
    n, osc = amostras(0.22), Oscilador()
    saida = []
    for i in range(n):
        vibrato = 1 + 0.04 * math.sin(2 * math.pi * 28 * i / TAXA)
        f = varredura(220, 620, i, n) * vibrato
        saida.append(0.8 * osc.triangular(f) * envelope(i, n, soltura=0.06, curva=0.7))
    return saida


# ---------- dano ----------

def dano_a():
    """"Ai!" curto: duas notas descendo, quadrada suave."""
    saida = []
    for f0, f1, dur in ((660, 520, 0.08), (440, 300, 0.14)):
        n, osc = amostras(dur), Oscilador()
        saida += [0.45 * osc.quadrada(varredura(f0, f1, i, n), 0.5) * envelope(i, n, soltura=0.02)
                  for i in range(n)]
    return saida


def dano_b():
    """"Bonk" de desenho: triangular caindo com baque grave."""
    rng = random.Random(7)
    n, osc, grave, filtro = amostras(0.26), Oscilador(), Oscilador(), PassaBaixa()
    saida = []
    for i in range(n):
        e = envelope(i, n, curva=1.6)
        tom = 0.7 * osc.triangular(varredura(520, 170, i, n))
        baque = 0.5 * grave.seno(varredura(140, 60, i, n)) * envelope(i, n, curva=3)
        estalo = 0.4 * filtro(ruido(rng), 1500) * max(0.0, 1 - i / amostras(0.03))
        saida.append((tom + baque) * e + estalo)
    return saida


# ---------- espada (Guerreiro) ----------

def _vush(rng, dur, f0, f1, volume=1.0):
    n, filtro = amostras(dur), PassaFaixa()
    saida = []
    for i in range(n):
        p = i / n
        forma = math.sin(math.pi * p) ** 1.5
        saida.append(volume * 2.2 * filtro(ruido(rng), varredura(f0, f1, i, n)) * forma)
    return saida


def _shing(dur, frequencias, volume=0.25):
    n = amostras(dur)
    oscs = [Oscilador() for _ in frequencias]
    return [volume * sum(o.seno(f) for o, f in zip(oscs, frequencias)) * envelope(i, n, curva=2.5)
            for i in range(n)]


def espada_a():
    """Vush + brilho metálico."""
    rng = random.Random(11)
    vush = _vush(rng, 0.22, 700, 2600)
    atraso = [0.0] * amostras(0.07)
    return misturar(vush, atraso + _shing(0.32, (2489, 3150, 4720, 6010)))


def espada_b():
    """Vush mais encorpado, sem brilho (mais "pesado")."""
    rng = random.Random(12)
    return misturar(_vush(rng, 0.26, 400, 1700, 1.2), _vush(rng, 0.2, 900, 3000, 0.5))


# ---------- raio ----------

def raio_a():
    """Estalo elétrico: zumbido grave com faíscas aleatórias."""
    rng = random.Random(21)
    n, osc, filtro = amostras(0.42), Oscilador(), PassaBaixa()
    saida, rajada = [], 0.0
    for i in range(n):
        if rng.random() < 0.004:
            rajada = 1.0
        rajada *= 0.996
        zumbido = 0.35 * osc.quadrada(110 + rng.uniform(-25, 25), 0.3)
        faisca = rajada * (ruido(rng) - filtro(ruido(rng), 2000))
        saida.append((zumbido + 0.9 * faisca) * envelope(i, n, ataque=0.002, curva=1.3))
    return saida


def raio_b():
    """Zap: quadrada despencando com modulação rápida."""
    n, osc, mod = amostras(0.3), Oscilador(), Oscilador()
    return [0.5 * osc.quadrada(varredura(1800, 160, i, n)) * (0.6 + 0.4 * mod.quadrada(55))
            * envelope(i, n, ataque=0.002, curva=1.2) for i in range(n)]


# ---------- fogo ----------

def fogo_a():
    """Fuum: ruído abafado que abre e fecha, com grave crescendo."""
    rng = random.Random(31)
    n, filtro, osc = amostras(0.38), PassaBaixa(), Oscilador()
    saida = []
    for i in range(n):
        p = i / n
        corte = 300 + 2500 * math.sin(math.pi * min(1.0, p * 1.3)) ** 2
        chiado = 1.6 * filtro(ruido(rng), corte)
        grave = 0.35 * osc.seno(varredura(70, 110, i, n))
        saida.append((chiado + grave) * math.sin(math.pi * p) ** 0.8)
    return saida


def fogo_b():
    """Bola de fogo: sopro curto descendo e estalinhos de brasa."""
    rng = random.Random(32)
    n, filtro, osc = amostras(0.34), PassaBaixa(), Oscilador()
    saida = []
    for i in range(n):
        sopro = 1.4 * filtro(ruido(rng), varredura(3500, 400, i, n))
        tom = 0.25 * osc.quadrada(varredura(380, 120, i, n), 0.4)
        brasa = 0.7 * ruido(rng) if rng.random() < 0.006 else 0.0
        saida.append((sopro + tom) * envelope(i, n, ataque=0.01, curva=1.1) + brasa)
    return saida


def fogo_c():
    """Puf! seco no início (ataque forte) e chiado curto de chama."""
    rng = random.Random(33)
    n, filtro, osc = amostras(0.26), PassaBaixa(), Oscilador()
    puf = amostras(0.03)
    saida = []
    for i in range(n):
        estouro = ruido(rng) * max(0.0, 1 - i / puf) * 1.2
        chama = 1.3 * filtro(ruido(rng), varredura(4000, 600, i, n)) * envelope(i, n, ataque=0.002, curva=1.4)
        tom = 0.35 * osc.quadrada(varredura(520, 140, i, n), 0.4) * envelope(i, n, ataque=0.001, curva=2)
        saida.append(math.tanh(2.5 * (estouro + chama + tom)))  # saturação: soa mais cheio
    return saida


def fogo_d():
    """Fwoosh: chama que acende num sopro (faixa de ruído que sobe e desce)."""
    rng = random.Random(34)
    n, faixa = amostras(0.32), PassaFaixa()
    saida, tremor = [], 1.0
    for i in range(n):
        p = i / n
        if i % amostras(0.02) == 0:
            tremor = rng.uniform(0.7, 1.0)
        centro = 900 + 2200 * math.sin(math.pi * min(1.0, p * 1.6))
        corpo = 3.0 * faixa(ruido(rng), centro) * tremor
        saida.append(math.tanh(2.0 * corpo) * envelope(i, n, ataque=0.004, curva=1.3))
    return saida


def fogo_e():
    """Bola de fogo 8-bit: tom quadrado caindo com chiado, bem de videogame."""
    rng = random.Random(35)
    n, osc, filtro = amostras(0.24), Oscilador(), PassaBaixa()
    saida = []
    for i in range(n):
        tom = 0.5 * osc.quadrada(varredura(1100, 260, i, n), 0.5)
        chiado = 0.6 * filtro(ruido(rng), 3000)
        saida.append((tom + chiado) * envelope(i, n, ataque=0.002, curva=1.6))
    return saida


def fogo_f():
    """Labareda: sopro curto e estalinhos de brasa bem audíveis."""
    rng = random.Random(36)
    n, faixa, estalos = amostras(0.34), PassaFaixa(), PassaFaixa()
    saida, estalo = [], 0.0
    for i in range(n):
        if rng.random() < 0.004:
            estalo = 1.0
        estalo *= 0.97
        sopro = 1.8 * faixa(ruido(rng), 1400) * envelope(i, n, ataque=0.003, curva=1.8)
        saida.append(math.tanh(2.2 * (sopro + 1.4 * estalo * estalos(ruido(rng), 3500))))
    return saida


# ---------- quique da bola de fogo (toca a cada batida no chão) ----------

def fogo_quique_a():
    """Pof + chiado: batida curta e a chama chiando ao tocar o chão."""
    rng = random.Random(37)
    n, grave, faixa = amostras(0.16), Oscilador(), PassaFaixa()
    saida = []
    for i in range(n):
        batida = 0.8 * grave.triangular(varredura(520, 220, i, n)) * envelope(i, n, ataque=0.001, curva=3)
        chiado = 1.6 * faixa(ruido(rng), 4000) * envelope(i, n, ataque=0.002, curva=1.5)
        saida.append(math.tanh(1.8 * (batida + chiado)))
    return saida


def fogo_quique_b():
    """Boing de fogo 8-bit: blip que sobe (como bola quicando) com chiado."""
    rng = random.Random(38)
    n, osc, filtro = amostras(0.12), Oscilador(), PassaBaixa()
    saida = []
    for i in range(n):
        tom = 0.55 * osc.quadrada(varredura(380, 900, i, n), 0.4)
        chiado = 0.4 * filtro(ruido(rng), 3500)
        saida.append((tom + chiado) * envelope(i, n, ataque=0.001, curva=1.8))
    return saida


def fogo_quique_c():
    """Tsss: só o chiado da brasa batendo, com um estalinho no início."""
    rng = random.Random(39)
    n, faixa = amostras(0.14), PassaFaixa()
    saida = []
    for i in range(n):
        estalo = 1.2 * ruido(rng) * max(0.0, 1 - i / amostras(0.012))
        chiado = 1.8 * faixa(ruido(rng), 5000) * envelope(i, n, ataque=0.004, curva=1.2)
        saida.append(math.tanh(1.6 * (estalo + chiado)))
    return saida


# ---------- terra ----------

def terra_a():
    """Estrondo: baque grave com pedrinhas batendo."""
    rng = random.Random(41)
    n, grave, filtro, pedras = amostras(0.5), Oscilador(), PassaBaixa(), PassaFaixa()
    saida, pedra = [], 0.0
    for i in range(n):
        baque = 0.9 * grave.seno(varredura(90, 38, i, n)) * envelope(i, n, curva=1.8)
        ronco = 1.5 * filtro(ruido(rng), 220) * envelope(i, n, curva=1.2)
        if i > amostras(0.05) and rng.random() < 0.0015:
            pedra = 1.0
        pedra *= 0.993
        saida.append(baque + ronco + 0.9 * pedra * pedras(ruido(rng), 1800))
    return saida


def terra_b():
    """Tum seco de pedra surgindo, mais curto."""
    rng = random.Random(42)
    n, grave, filtro = amostras(0.3), Oscilador(), PassaBaixa()
    saida = []
    for i in range(n):
        baque = grave.triangular(varredura(160, 55, i, n)) * envelope(i, n, ataque=0.002, curva=2.2)
        crec = 1.2 * filtro(ruido(rng), 900) * envelope(i, n, ataque=0.002, curva=3)
        saida.append(0.8 * baque + crec)
    return saida


# ---------- água (bolha) ----------

def _blup(f0, f1, dur, volume=0.7):
    n, osc = amostras(dur), Oscilador()
    return [volume * osc.seno(varredura(f0, f1, i, n)) * envelope(i, n, ataque=0.003, curva=1.4)
            for i in range(n)]


def bolha_a():
    """Blup! grande subindo."""
    return misturar(_blup(260, 980, 0.18), [0.0] * amostras(0.09) + _blup(420, 1300, 0.12, 0.4))


def bolha_b():
    """Três bolhinhas subindo em escada."""
    saida = []
    for f0, f1 in ((500, 1100), (650, 1400), (820, 1800)):
        saida += _blup(f0, f1, 0.07, 0.6) + [0.0] * amostras(0.025)
    return saida


def bolha_c():
    """Blup agudo e imediato (triangular), audível em alto-falante de celular."""
    n, osc = amostras(0.15), Oscilador()
    return [0.8 * osc.triangular(varredura(600, 1600, i, n)) * envelope(i, n, ataque=0.002, curva=1.2)
            for i in range(n)]


# ---------- carga do poder (som contínuo subindo enquanto segura, ~1,3 s) ----------

def carga_a():
    """Energia subindo: quadrada fina com vibrato que acelera e chiado que abre."""
    rng = random.Random(61)
    n, osc, filtro = amostras(1.3), Oscilador(), PassaBaixa()
    saida = []
    for i in range(n):
        p = i / n
        vibrato = 1 + 0.03 * math.sin(2 * math.pi * (6 + 20 * p) * i / TAXA)
        tom = 0.35 * osc.quadrada(varredura(330, 1320, i, n) * vibrato, 0.25)
        chiado = 0.5 * filtro(ruido(rng), 500 + 3500 * p)
        volume = 0.35 + 0.65 * p
        saida.append((tom + chiado) * volume * min(1.0, (n - i) / amostras(0.05)))
    return saida


def carga_b():
    """Brilho mágico: notas rápidas subindo (arpejo) cada vez mais agudas."""
    escala = [523, 659, 784, 1047, 1319, 1568, 2093, 2637]
    saida = []
    for k, f in enumerate(escala):
        n, osc, eco = amostras(0.16), Oscilador(), Oscilador()
        volume = 0.4 + 0.08 * k
        saida += [volume * (0.7 * osc.triangular(f) + 0.3 * eco.seno(f * 2)) * envelope(i, n, ataque=0.003, curva=1.2)
                  for i in range(n)]
    return saida


def carga_c():
    """Vuuuum: tom cheio subindo liso, com tremolo que acelera."""
    n, a, b = amostras(1.3), Oscilador(), Oscilador()
    saida = []
    for i in range(n):
        p = i / n
        f = varredura(400, 1600, i, n)
        tremolo = 0.7 + 0.3 * math.sin(2 * math.pi * (4 + 16 * p) * i / TAXA)
        valor = 0.5 * a.triangular(f) + 0.25 * b.quadrada(f * 1.5, 0.5)
        saida.append(valor * tremolo * (0.4 + 0.6 * p) * min(1.0, (n - i) / amostras(0.05)))
    return saida


SONS = {
    "pulo": (pulo_a, pulo_b),
    "dano": (dano_a, dano_b),
    "espada": (espada_a, espada_b),
    "raio": (raio_a, raio_b),
    "fogo": (fogo_a, fogo_b, fogo_c, fogo_d, fogo_e, fogo_f),
    "fogo_quique": (fogo_quique_a, fogo_quique_b, fogo_quique_c),
    "terra": (terra_a, terra_b),
    "bolha": (bolha_a, bolha_b, bolha_c),
    "carga": (carga_a, carga_b, carga_c),
}

# Versão escolhida pelo Jean de ouvido (2026-11-12).
ESCOLHIDOS = {
    "pulo": "b",
    "dano": "b",
    "espada": "a",
    "raio": "a",
    "fogo": "f",  # labareda; a "b" tinha ataque fraco e a "c" (puf seco) soou estranha
    "fogo_quique": "c",
    "terra": "b",
    "bolha": "c",  # a "a" (seno grave) atrasava e sumia no alto-falante do celular
    "carga": "c",
}


def main():
    argumentos = argparse.ArgumentParser(description=__doc__)
    argumentos.add_argument("--previa", type=Path)
    previa = argumentos.parse_args().previa
    if previa is not None:
        previa.mkdir(parents=True, exist_ok=True)
        for nome, versoes in SONS.items():
            for letra, gerar in zip("abcdef", versoes):
                salvar(gerar(), previa / f"{nome}_{letra}.wav")
        return
    destino = Path(__file__).resolve().parent.parent / "assets" / "audio"
    for nome, letra in ESCOLHIDOS.items():
        salvar(SONS[nome]["abcdef".index(letra)](), destino / f"{nome}.wav")


if __name__ == "__main__":
    main()
