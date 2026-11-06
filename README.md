# Aventura

Jogo de plataforma em Flutter feito para os meus filhos: escolha um herói com um poder (espada, raio, fogo, terra ou água), corra, pule, pegue as moedas, derrote os monstros e chegue até a bandeira.

Roda em celular e tablet Android e também em TV box Android, com controle remoto ou controle de videogame Bluetooth.

## Como jogar

| Ação | Toque | Teclado | Controle da TV | Controle Bluetooth |
|---|---|---|---|---|
| Andar | botões ← → | setas ou A / D | setas | direcional |
| Pular | botão ↑ | espaço, ↑ ou W | botão do meio (OK) | A |
| Usar o poder | botão com o ícone do herói | X, J ou ↓ | seta ↓ | B, X ou Y |

- Segurar o pulo faz o herói pular mais alto.
- Pular em cima de um inimigo também causa dano; encostar de lado tira um coração.
- A bandeira do meio da fase guarda o progresso: depois de perder os corações, o jogo volta dela.
- A mola joga o herói lá para cima.
- O botão de nota musical, no canto de cima, liga e desliga a música.

## Heróis

| Herói | Poder | Corações |
|---|---|---|
| Guerreiro | Espadada curta à frente | 4 |
| Mago do Raio | Raio rápido em linha reta, atravessa inimigos | 3 |
| Mago do Fogo | Bola de fogo que quica no chão | 3 |
| Maga da Terra | Levanta um bloco de pedra na frente (degrau e parede, some depois de alguns segundos) | 3 |
| Maga da Água | Bolha que prende o inimigo; dá para subir em cima dele | 3 |

Inimigos e fraquezas:

| Inimigo | Vida | Detalhe |
|---|---|---|
| Slime | 1 | qualquer poder derrota |
| Slime de fogo | 2 | imune a fogo; a água derrota na hora |
| Morcego | 1 | voa; o raio causa dano dobrado |
| Golem de pedra | 4 | o raio causa dano dobrado; o fogo faz pouco efeito |

## Rodando

```bash
fvm flutter pub get
fvm flutter run
```

### Instalar na TV box

```bash
fvm flutter build apk --release
adb connect <ip-da-tv-box>
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Sem `adb`, dá para copiar o `app-release.apk` para um pendrive e instalar pelo gerenciador de arquivos da TV box (é preciso permitir apps de fontes desconhecidas). O jogo aparece no menu da TV como **Aventura**.

## Editando a fase

A fase fica em `assets/tiles/fase1.tmx`, no formato do [Tiled](https://www.mapeditor.org/) (gratuito):

- camada **terreno**: blocos em que o herói pisa e bate;
- camada **decoracao**: plantas, placas e árvores, sem colisão;
- camada **objetos**: retângulos com nome `inicio`, `moeda`, `mola`, `checkpoint`, `chegada` ou um inimigo: `slime`, `slime_fogo`, `morcego` ou `golem`.

Abra o arquivo no Tiled, desenhe com os blocos de `blocos.png`, salve e rode o jogo de novo.

A versão inicial da fase foi gerada por `ferramentas/gerar_fase1.py`. Rodar o script de novo **sobrescreve** as edições feitas no Tiled.

## Música

A música de fundo é uma composição original, gerada por `ferramentas/gerar_musica.py` (Python puro, sem dependências): melodia 8-bit, baixo e bateria, em Dó maior a 150 BPM, com 16 compassos que repetem sem emenda. Para mudar a música, edite as linhas de `MELODIA` e `ACORDES` no script e rode:

```bash
python3 ferramentas/gerar_musica.py
```

## Estrutura

```
lib/
  main.dart            app, tela cheia e telas sobre o jogo
  jogo/
    aventura_jogo.dart estado do jogo, câmera, corações, vitória e derrota
    fase.dart          carrega o mapa, colisão com os blocos, moedas, inimigos e bandeiras
    classes.dart       os cinco heróis e seus poderes
    heroi.dart         física do herói (aceleração, pulo variável, coyote time) e uso do poder
    poderes.dart       espadada, raio, bola de fogo, bolha e pedra mágica
    inimigo.dart       slime, slime de fogo, morcego e golem, com vida e fraquezas
    itens.dart         moeda, mola e bandeira
    controle.dart      toque, teclado, controle remoto e gamepad
  telas/               escolha do herói, placar, botões de toque, vitória e derrota
assets/
  images/ tiles/ audio/
```

Feito com [Flame](https://flame-engine.org/) e [flame_tiled](https://pub.dev/packages/flame_tiled).

## Créditos

Arte e efeitos sonoros: [Kenney](https://kenney.nl) — pacotes *Pixel Platformer*, *Tiny Dungeon*, *Digital Audio* e *Music Jingles*, licença CC0 (`assets/LICENCA-KENNEY*.txt`). Os magos, as magas, o slime de fogo e o golem são versões recoloridas dos personagens do *Tiny Dungeon*.

Música de fundo: composição original deste projeto.
