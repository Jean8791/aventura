#!/usr/bin/env python3
"""Gera as fases do jogo em assets/tiles/faseN.tmx.

Os arquivos gerados abrem no editor Tiled (https://www.mapeditor.org/), onde podem ser
ajustados à mão. Rodar este script de novo sobrescreve as edições feitas no Tiled.

Camadas de cada mapa:
  decoracao  blocos sem colisão (plantas, placas, árvores)
  terreno    blocos sólidos (chão, plataformas, caixas)
  objetos    retângulos com nome:
               inicio, moeda, diamante, mola, checkpoint, chegada
               slime, slime_fogo, morcego, golem
               gelo (o fogo derrete), rachada (espada e raio quebram), fogueira (a água apaga)
               coracao (recupera um coração)
               plataforma_h e plataforma_v (plataforma que vai e volta dentro do retângulo)
               chefe (o retângulo é a arena do Feiticeiro das Sombras)

Regra de desenho: o caminho principal precisa ser possível com qualquer herói. Os obstáculos
de elemento guardam os diamantes, e cada herói alcança uma parte deles.
"""

from pathlib import Path

ALTURA = 15
TAM = 18
TOPO = 12

TEMAS = {
    "grama": {"plataforma": 0, "chao": 20},
    "neve": {"plataforma": 80, "chao": 100},
    "areia": {"plataforma": 40, "chao": 60},
    "caverna": {"plataforma": 140, "chao": 120},
}


class Mapa:
    def __init__(self, largura, tema):
        self.largura = largura
        self.tema = TEMAS[tema]
        self.solido = {}
        self.decor_ = {}
        self.objetos = []

    def chao(self, c0, c1, topo=TOPO):
        for c in range(c0, c1 + 1):
            for r in range(topo, ALTURA):
                self.solido[(c, r)] = "chao"

    def teto(self, c0, c1, ate_linha):
        for c in range(c0, c1 + 1):
            for r in range(0, ate_linha + 1):
                self.solido[(c, r)] = "teto"

    def plataforma_movel(self, sentido, c0, r0, c1, r1):
        self.obj(f"plataforma_{sentido}", c0, r0, c1 - c0 + 1, r1 - r0 + 1)

    def plataforma(self, c0, c1, linha):
        for c in range(c0, c1 + 1):
            self.solido[(c, linha)] = "plataforma"

    def bloco(self, c, linha, tipo=9):
        self.solido[(c, linha)] = tipo

    def coluna_de_blocos(self, c, r0, r1, tipo=9):
        for r in range(r0, r1 + 1):
            self.bloco(c, r, tipo)

    def linha_de_blocos(self, c0, c1, r, tipo=9):
        for c in range(c0, c1 + 1):
            self.bloco(c, r, tipo)

    def escada(self, c0, degraus, subindo=True, base=TOPO - 1):
        for i in range(degraus):
            altura = i + 1 if subindo else degraus - i
            for h in range(altura):
                self.bloco(c0 + i, base - h)

    def decor(self, c, linha, tile):
        self.decor_[(c, linha)] = tile

    def obj(self, nome, c, linha, largura=1, altura=1):
        self.objetos.append((nome, c, linha, largura, altura))

    def moedas(self, c0, c1, linha):
        for c in range(c0, c1 + 1):
            self.obj("moeda", c, linha)

    def arco_moedas(self, c0, linha_base):
        for i, dy in enumerate([0, 1, 2, 2, 1, 0]):
            self.obj("moeda", c0 + i, linha_base - dy)

    def parede(self, nome, c, r0, r1):
        for r in range(r0, r1 + 1):
            self.obj(nome, c, r)

    def cofre(self, c0, c1, porta, lado="direita"):
        """Salinha de caixas com um diamante dentro e uma porta de obstáculo num dos lados."""
        self.linha_de_blocos(c0, c1, TOPO - 3)
        parede_fixa, parede_porta = (c0, c1) if lado == "direita" else (c1, c0)
        self.coluna_de_blocos(parede_fixa, TOPO - 2, TOPO - 1)
        self.parede(porta, parede_porta, TOPO - 2, TOPO - 1)
        self.obj("diamante", (c0 + c1) // 2, TOPO - 1)

    def _tile_terreno(self, c, r):
        tipo = self.solido.get((c, r))
        if tipo is None:
            return 0
        if isinstance(tipo, int):
            return tipo + 1
        esq = self.solido.get((c - 1, r)) == tipo
        dir_ = self.solido.get((c + 1, r)) == tipo
        if tipo == "plataforma":
            base = self.tema["plataforma"]
            return base + (2 if esq and dir_ else 1 if dir_ else 3 if esq else 0) + 1
        if tipo == "teto":
            abaixo = self.solido.get((c, r + 1)) == "teto"
            base = 120 if abaixo else 140
            return base + (2 if esq and dir_ else 1 if dir_ else 3 if esq else 0) + 1
        acima = self.solido.get((c, r - 1)) == "chao"
        base = 120 if acima else self.tema["chao"]
        return base + (2 if esq and dir_ else 1 if dir_ else 3 if esq else 0) + 1

    def _csv(self, func):
        return ",\n".join(
            ",".join(str(func(c, r)) for c in range(self.largura)) for r in range(ALTURA)
        )

    def salvar(self, nome_do_arquivo):
        partes = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" '
            f'width="{self.largura}" height="{ALTURA}" tilewidth="{TAM}" tileheight="{TAM}" infinite="0" '
            f'nextlayerid="4" nextobjectid="{len(self.objetos) + 1}">',
            ' <tileset firstgid="1" name="blocos" tilewidth="18" tileheight="18" tilecount="180" columns="20">',
            '  <image source="blocos.png" width="360" height="162"/>',
            ' </tileset>',
            f' <layer id="1" name="decoracao" width="{self.largura}" height="{ALTURA}">',
            '  <data encoding="csv">',
            self._csv(lambda c, r: self.decor_.get((c, r), -1) + 1),
            '  </data>',
            ' </layer>',
            f' <layer id="2" name="terreno" width="{self.largura}" height="{ALTURA}">',
            '  <data encoding="csv">',
            self._csv(self._tile_terreno),
            '  </data>',
            ' </layer>',
            ' <objectgroup id="3" name="objetos">',
        ]
        for i, (nome, c, r, w, h) in enumerate(self.objetos, start=1):
            partes.append(
                f'  <object id="{i}" name="{nome}" x="{c * TAM}" y="{r * TAM}" '
                f'width="{w * TAM}" height="{h * TAM}"/>'
            )
        partes += [" </objectgroup>", "</map>", ""]
        destino = Path(__file__).resolve().parent.parent / "assets" / "tiles" / nome_do_arquivo
        destino.write_text("\n".join(partes), encoding="utf-8")
        diamantes = sum(1 for o in self.objetos if o[0] == "diamante")
        print(f"{destino.name}: {self.largura}x{ALTURA} blocos, {len(self.objetos)} objetos, {diamantes} diamantes")


def fase1():
    m = Mapa(170, "grama")

    m.chao(0, 21)
    m.obj("inicio", 8, TOPO - 2)
    m.decor(11, TOPO - 1, 85)
    m.decor(13, TOPO - 1, 124)
    m.decor(3, TOPO - 1, 126)
    m.moedas(10, 14, TOPO - 3)
    m.plataforma(16, 19, 9)
    m.moedas(16, 19, 8)

    m.chao(24, 41)
    m.decor(26, TOPO - 1, 125)
    m.plataforma(29, 32, 9)
    m.moedas(29, 32, 8)
    m.obj("slime", 36, TOPO - 1)
    m.decor(39, TOPO - 1, 128)

    m.escada(42, 3)
    m.chao(42, 44)
    m.chao(48, 63)
    m.escada(48, 3, subindo=False)
    m.arco_moedas(43, 6)
    m.decor(53, TOPO - 1, 124)

    m.obj("mola", 55, TOPO - 1)
    m.moedas(54, 56, 2)
    m.moedas(54, 56, 3)
    m.obj("diamante", 55, 1)
    m.obj("slime_fogo", 60, TOPO - 1)

    m.obj("checkpoint", 62, TOPO - 2, 1, 2)

    m.chao(64, 67)
    m.plataforma(70, 72, 10)
    m.plataforma(75, 77, 9)
    m.chao(80, 102)
    m.moedas(70, 72, 9)
    m.moedas(75, 76, 8)
    m.obj("diamante", 77, 8)
    m.decor(82, TOPO - 1, 105)
    m.decor(83, TOPO - 1, 106)
    m.obj("slime", 88, TOPO - 1)
    m.obj("morcego", 92, 7)
    m.arco_moedas(90, 8)
    m.obj("slime_fogo", 97, TOPO - 1)
    m.decor(99, TOPO - 1, 126)

    m.escada(103, 4)
    m.chao(103, 120)
    m.escada(107, 4, subindo=False)
    m.moedas(104, 109, 6)
    m.decor(113, TOPO - 1, 124)
    m.decor(115, TOPO - 1, 125)

    m.chao(121, 132, topo=10)
    m.moedas(122, 131, 9)
    m.obj("golem", 127, 9)
    m.obj("morcego", 136, 5)
    m.plataforma(135, 137, 9)
    m.chao(133, 169)
    m.moedas(135, 137, 8)
    m.obj("mola", 140, TOPO - 1)
    m.moedas(140, 140, 4)
    m.moedas(140, 140, 5)

    m.escada(146, 5)
    for c in range(151, 154):
        for h in range(5):
            m.bloco(c, TOPO - 1 - h)
    m.obj("diamante", 152, TOPO - 7)
    m.obj("chegada", 160, TOPO - 3, 1, 3)
    m.decor(164, TOPO - 1, 126)
    m.decor(166, TOPO - 1, 128)
    m.salvar("fase1.tmx")


def fase2():
    m = Mapa(180, "neve")

    m.chao(0, 25)
    m.obj("inicio", 9, TOPO - 2)
    m.decor(3, TOPO - 1, 126)
    m.decor(9, TOPO - 1, 145)
    m.decor(12, TOPO - 1, 85)
    m.moedas(14, 18, TOPO - 3)
    m.obj("slime", 21, TOPO - 1)

    m.chao(28, 45)
    m.plataforma(31, 34, 9)
    m.moedas(31, 34, 8)
    m.parede("gelo", 40, TOPO - 2, TOPO - 1)
    m.moedas(39, 41, TOPO - 4)
    m.decor(44, TOPO - 1, 126)

    m.chao(49, 70)
    m.cofre(54, 58, "gelo", lado="direita")
    m.moedas(60, 62, TOPO - 2)
    m.obj("morcego", 64, 7)
    m.decor(66, TOPO - 1, 145)
    m.obj("checkpoint", 68, TOPO - 2, 1, 2)

    m.plataforma(72, 74, 10)
    m.moedas(72, 74, 9)
    m.chao(77, 102)
    m.cofre(80, 84, "rachada", lado="esquerda")
    m.moedas(86, 89, TOPO - 2)
    m.obj("slime", 92, TOPO - 1)
    m.obj("golem", 98, TOPO - 1)
    m.parede("gelo", 95, TOPO - 1, TOPO - 1)

    m.escada(103, 4)
    m.chao(103, 140)
    m.escada(107, 4, subindo=False)
    m.moedas(104, 109, 6)
    m.obj("morcego", 113, 8)
    m.plataforma(118, 120, TOPO - 6)
    m.obj("diamante", 119, TOPO - 7)
    m.decor(123, TOPO - 1, 145)
    m.arco_moedas(126, 8)
    m.obj("slime", 133, TOPO - 1)
    m.parede("rachada", 137, TOPO - 2, TOPO - 1)

    m.plataforma(143, 145, 10)
    m.moedas(143, 145, 9)
    m.chao(148, 179)
    m.obj("mola", 151, TOPO - 1)
    m.moedas(151, 151, 3)
    m.moedas(151, 151, 4)
    m.escada(157, 5)
    for c in range(162, 165):
        for h in range(5):
            m.bloco(c, TOPO - 1 - h)
    m.obj("chegada", 171, TOPO - 3, 1, 3)
    m.decor(175, TOPO - 1, 126)
    m.decor(177, TOPO - 1, 145)
    m.salvar("fase2.tmx")


def fase3():
    m = Mapa(180, "areia")

    m.chao(0, 24)
    m.obj("inicio", 9, TOPO - 2)
    m.decor(3, TOPO - 1, 127)
    m.decor(10, TOPO - 1, 85)
    m.obj("fogueira", 14, TOPO - 1)
    m.moedas(13, 15, TOPO - 4)
    m.obj("slime_fogo", 20, TOPO - 1)

    m.chao(28, 52)
    m.linha_de_blocos(36, 45, TOPO - 2)
    m.coluna_de_blocos(45, TOPO - 1, TOPO - 1)
    m.obj("fogueira", 39, TOPO - 1)
    m.obj("fogueira", 42, TOPO - 1)
    m.obj("diamante", 44, TOPO - 1)
    m.moedas(37, 44, TOPO - 3)
    m.decor(49, TOPO - 1, 127)

    m.obj("golem", 56, TOPO - 1)
    m.chao(53, 66)
    m.decor(60, TOPO - 1, 127)
    m.obj("checkpoint", 64, TOPO - 2, 1, 2)

    m.plataforma(68, 70, 10)
    m.moedas(68, 70, 9)
    m.chao(73, 104)
    m.cofre(76, 80, "rachada", lado="esquerda")
    m.obj("fogueira", 88, TOPO - 1)
    m.obj("fogueira", 92, TOPO - 1)
    m.moedas(87, 93, TOPO - 4)
    m.obj("slime_fogo", 96, TOPO - 1)
    m.obj("morcego", 100, 7)
    m.decor(103, TOPO - 1, 127)

    m.chao(105, 140)
    m.obj("morcego", 110, 8)
    m.plataforma(115, 117, TOPO - 6)
    m.obj("diamante", 116, TOPO - 7)
    m.obj("golem", 124, TOPO - 1)
    m.obj("mola", 128, TOPO - 1)
    m.moedas(128, 128, 3)
    m.moedas(128, 128, 4)
    m.obj("fogueira", 134, TOPO - 1)
    m.decor(138, TOPO - 1, 127)

    m.plataforma(143, 145, 10)
    m.moedas(143, 145, 9)
    m.chao(148, 179)
    m.obj("slime_fogo", 152, TOPO - 1)
    m.escada(157, 5)
    for c in range(162, 165):
        for h in range(5):
            m.bloco(c, TOPO - 1 - h)
    m.obj("chegada", 171, TOPO - 3, 1, 3)
    m.decor(175, TOPO - 1, 127)
    m.salvar("fase3.tmx")


def fase4():
    m = Mapa(180, "caverna")

    m.teto(0, 179, 0)
    m.chao(0, 24)
    m.teto(0, 20, 2)
    m.obj("inicio", 9, TOPO - 2)
    m.decor(12, TOPO - 1, 85)
    m.moedas(14, 18, TOPO - 3)
    m.obj("slime", 21, TOPO - 1)

    m.plataforma_movel("h", 26, TOPO - 2, 33, TOPO - 2)
    m.moedas(27, 32, TOPO - 4)

    m.chao(35, 58)
    m.obj("morcego", 39, 6)
    m.cofre(43, 47, "gelo", lado="direita")
    m.moedas(49, 52, TOPO - 2)
    m.obj("golem", 54, TOPO - 1)
    m.obj("checkpoint", 57, TOPO - 2, 1, 2)

    m.plataforma_movel("v", 61, 6, 63, TOPO - 1)
    m.plataforma_movel("h", 65, 6, 72, 6)
    m.moedas(66, 71, 4)
    m.obj("coracao", 69, 3)
    m.chao(75, 100)
    m.teto(78, 90, 5)
    m.moedas(79, 89, TOPO - 2)
    m.obj("slime_fogo", 86, TOPO - 1)
    m.cofre(92, 96, "rachada", lado="esquerda")

    m.plataforma_movel("h", 102, TOPO - 2, 109, TOPO - 2)
    m.chao(111, 140)
    m.obj("morcego", 114, 8)
    m.plataforma(119, 121, TOPO - 6)
    m.obj("diamante", 120, TOPO - 7)
    m.obj("fogueira", 126, TOPO - 1)
    m.obj("golem", 131, TOPO - 1)
    m.obj("slime_fogo", 137, TOPO - 1)

    m.plataforma_movel("v", 142, 6, 144, TOPO - 1)
    m.moedas(143, 143, 4)
    m.chao(147, 179)
    m.obj("coracao", 150, TOPO - 1)
    m.escada(157, 5)
    for c in range(162, 165):
        for h in range(5):
            m.bloco(c, TOPO - 1 - h)
    m.obj("chegada", 171, TOPO - 3, 1, 3)
    m.salvar("fase4.tmx")


def fase5():
    m = Mapa(40, "caverna")

    m.teto(0, 39, 1)
    m.chao(0, 39)
    for c in (0, 39):
        for r in range(2, TOPO):
            m.bloco(c, r)
    m.obj("inicio", 4, TOPO - 2)
    m.plataforma(6, 9, 8)
    m.plataforma(30, 33, 8)
    m.plataforma(17, 22, 5)
    m.obj("coracao", 7, 7)
    m.obj("coracao", 32, 7)
    m.moedas(18, 21, 4)
    m.obj("chefe", 2, 3, 36, TOPO - 3)
    m.salvar("fase5.tmx")


if __name__ == "__main__":
    fase1()
    fase2()
    fase3()
    fase4()
    fase5()
