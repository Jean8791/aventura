#!/usr/bin/env python3
"""Gera assets/tiles/fase1.tmx, a primeira fase do jogo.

O arquivo gerado abre no editor Tiled (https://www.mapeditor.org/), onde a fase
pode ser ajustada à mão. Rodar este script de novo sobrescreve as edições feitas no Tiled.

Camadas do mapa:
  decoracao  blocos sem colisão (plantas, placas, árvores)
  terreno    blocos sólidos (chão, plataformas, caixas)
  objetos    retângulos com nome: inicio, moeda, inimigo, mola, checkpoint, chegada
"""

from pathlib import Path

LARGURA = 170
ALTURA = 15
TAM = 18
TOPO = 12

SOLIDO = {}
DECOR = {}
OBJETOS = []


def chao(c0, c1, topo=TOPO):
    for c in range(c0, c1 + 1):
        for r in range(topo, ALTURA):
            SOLIDO[(c, r)] = "chao"


def plataforma(c0, c1, linha):
    for c in range(c0, c1 + 1):
        SOLIDO[(c, linha)] = "plataforma"


def bloco(c, linha, tipo=9):
    SOLIDO[(c, linha)] = tipo


def escada(c0, degraus, subindo=True, base=TOPO - 1):
    for i in range(degraus):
        altura = i + 1 if subindo else degraus - i
        for h in range(altura):
            bloco(c0 + i, base - h)


def decor(c, linha, tile):
    DECOR[(c, linha)] = tile


def obj(nome, c, linha, largura=1, altura=1):
    OBJETOS.append((nome, c, linha, largura, altura))


def moedas(c0, c1, linha):
    for c in range(c0, c1 + 1):
        obj("moeda", c, linha)


def arco_moedas(c0, linha_base):
    for i, dy in enumerate([0, 1, 2, 2, 1, 0]):
        obj("moeda", c0 + i, linha_base - dy)


# Início: chão plano para aprender a andar e pular
chao(0, 21)
obj("inicio", 8, TOPO - 2)
decor(11, TOPO - 1, 85)
decor(13, TOPO - 1, 124)
decor(3, TOPO - 1, 126)
moedas(10, 14, TOPO - 3)
plataforma(16, 19, 9)
moedas(16, 19, 8)

# Primeiro buraco, bem curto
chao(24, 41)
decor(26, TOPO - 1, 125)
plataforma(29, 32, 9)
moedas(29, 32, 8)
obj("inimigo", 36, TOPO - 1)
decor(39, TOPO - 1, 128)

# Escadinha de caixas e buraco de 3 blocos
escada(42, 3)
chao(42, 44)
chao(48, 63)
escada(48, 3, subindo=False)
arco_moedas(43, 6)
decor(53, TOPO - 1, 124)

# Mola que joga lá para cima
obj("mola", 55, TOPO - 1)
moedas(54, 56, 2)
moedas(54, 56, 3)
obj("inimigo", 60, TOPO - 1)

# Bandeira do meio da fase
obj("checkpoint", 62, TOPO - 2, 1, 2)

# Buraco largo com pedrinhas para pular
chao(64, 67)
plataforma(70, 72, 10)
plataforma(75, 77, 9)
chao(80, 102)
moedas(70, 72, 9)
moedas(75, 77, 8)
decor(82, TOPO - 1, 105)
decor(83, TOPO - 1, 106)
obj("inimigo", 88, TOPO - 1)
arco_moedas(90, 8)
obj("inimigo", 96, TOPO - 1)
decor(99, TOPO - 1, 126)

# Morrinho de caixas
escada(103, 4)
chao(103, 120)
escada(107, 4, subindo=False)
moedas(104, 109, 6)
decor(113, TOPO - 1, 124)
decor(115, TOPO - 1, 125)

# Chão mais alto com plataformas
chao(121, 132, topo=10)
moedas(122, 131, 9)
obj("inimigo", 127, 9)
plataforma(135, 137, 9)
chao(133, LARGURA - 1)
moedas(135, 137, 8)
obj("mola", 140, TOPO - 1)
moedas(140, 140, 4)
moedas(140, 140, 5)

# Escadaria final até a bandeira
escada(146, 5)
for c in range(151, 154):
    for h in range(5):
        bloco(c, TOPO - 1 - h)
obj("chegada", 160, TOPO - 3, 1, 3)
decor(164, TOPO - 1, 126)
decor(166, TOPO - 1, 128)


def tile_terreno(c, r):
    tipo = SOLIDO.get((c, r))
    if tipo is None:
        return 0
    if isinstance(tipo, int):
        return tipo + 1
    esq = SOLIDO.get((c - 1, r)) == tipo
    dir_ = SOLIDO.get((c + 1, r)) == tipo
    if tipo == "plataforma":
        base = 2 if esq and dir_ else 1 if dir_ else 3 if esq else 0
        return base + 1
    acima = SOLIDO.get((c, r - 1)) == "chao"
    if not acima:
        base = 22 if esq and dir_ else 21 if dir_ else 23 if esq else 20
    else:
        base = 122 if esq and dir_ else 121 if dir_ else 123 if esq else 120
    return base + 1


def csv(func):
    linhas = []
    for r in range(ALTURA):
        linhas.append(",".join(str(func(c, r)) for c in range(LARGURA)))
    return ",\n".join(linhas)


def main():
    partes = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" '
        f'width="{LARGURA}" height="{ALTURA}" tilewidth="{TAM}" tileheight="{TAM}" infinite="0" '
        f'nextlayerid="4" nextobjectid="{len(OBJETOS) + 1}">',
        ' <tileset firstgid="1" name="blocos" tilewidth="18" tileheight="18" tilecount="180" columns="20">',
        '  <image source="blocos.png" width="360" height="162"/>',
        ' </tileset>',
        f' <layer id="1" name="decoracao" width="{LARGURA}" height="{ALTURA}">',
        '  <data encoding="csv">',
        csv(lambda c, r: DECOR.get((c, r), -1) + 1),
        '  </data>',
        ' </layer>',
        f' <layer id="2" name="terreno" width="{LARGURA}" height="{ALTURA}">',
        '  <data encoding="csv">',
        csv(tile_terreno),
        '  </data>',
        ' </layer>',
        ' <objectgroup id="3" name="objetos">',
    ]
    for i, (nome, c, r, w, h) in enumerate(OBJETOS, start=1):
        partes.append(
            f'  <object id="{i}" name="{nome}" x="{c * TAM}" y="{r * TAM}" '
            f'width="{w * TAM}" height="{h * TAM}"/>')
    partes += [' </objectgroup>', '</map>', '']

    destino = Path(__file__).resolve().parent.parent / "assets" / "tiles" / "fase1.tmx"
    destino.write_text("\n".join(partes), encoding="utf-8")
    print(f"{destino} gerado: {LARGURA}x{ALTURA} blocos, {len(OBJETOS)} objetos")


if __name__ == "__main__":
    main()
