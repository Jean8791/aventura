# Aventura

Jogo de plataforma em Flutter feito para os meus filhos: escolha um herói, corra, pule, pegue as moedas, pise nos robozinhos e chegue até a bandeira.

Roda em celular e tablet Android e também em TV box Android, com controle remoto ou controle de videogame Bluetooth.

## Como jogar

| Ação | Toque | Teclado | Controle da TV | Controle Bluetooth |
|---|---|---|---|---|
| Andar | botões ← → | setas ou A / D | setas | direcional |
| Pular | botão ↑ | espaço, ↑ ou W | botão do meio (OK) | A ou B |

- Segurar o pulo faz o herói pular mais alto.
- Pular em cima de um inimigo derrota ele; encostar de lado tira um coração.
- A bandeira do meio da fase guarda o progresso: depois de perder os corações, o jogo volta dela.
- A mola joga o herói lá para cima.
- O botão de nota musical, no canto de cima, liga e desliga a música.

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
- camada **objetos**: retângulos com nome `inicio`, `moeda`, `inimigo`, `mola`, `checkpoint` ou `chegada`.

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
    heroi.dart         física do herói (aceleração, pulo variável, coyote time)
    inimigo.dart       robozinho que anda e vira na beirada
    itens.dart         moeda, mola e bandeira
    controle.dart      toque, teclado, controle remoto e gamepad
  telas/               escolha do herói, placar, botões de toque, vitória e derrota
assets/
  images/ tiles/ audio/
```

Feito com [Flame](https://flame-engine.org/) e [flame_tiled](https://pub.dev/packages/flame_tiled).

## Créditos

Arte e efeitos sonoros: [Kenney](https://kenney.nl) — pacotes *Pixel Platformer*, *Digital Audio* e *Music Jingles*, licença CC0 (`assets/LICENCA-KENNEY.txt`).

Música de fundo: composição original deste projeto.
