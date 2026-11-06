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

## Dois jogadores

Na tela inicial, escolha **2 jogadores**. Cada jogador aperta um botão no próprio controle para entrar (controle Bluetooth, controle remoto da TV box ou teclado) e depois escolhe o seu herói.

- No teclado, dá para jogar os dois: o jogador que entrar com W, A, S ou D usa essas teclas (W pula, S usa o poder); o outro usa as setas.
- A câmera fica entre os dois, e ninguém sai da tela: um precisa esperar o outro.
- Cada um tem os seus corações. Quem cai num buraco reaparece ao lado do companheiro. Quem perde todos os corações desmaia por 3 segundos e volta ao lado do companheiro com os corações cheios. A fase só recomeça se os dois desmaiarem.
- Moedas e diamantes são do time.

Para saber de qual controle veio cada botão, o app lê os eventos no Android (`MainActivity.kt`) e os envia ao Flutter pelo canal `aventura/controles` com o número do dispositivo.

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

## Fases

| Fase | Tema | Obstáculos |
|---|---|---|
| 1. Floresta | grama | buracos, mola, escadinhas |
| 2. Montanha Gelada | neve | gelo, parede rachada |
| 3. Deserto de Fogo | areia | fogueiras, túnel em chamas, parede rachada |

O caminho até a bandeira é possível com qualquer herói. Cada fase esconde 3 diamantes, e muitos deles ficam atrás de obstáculos de elemento, então cada herói alcança uma parte:

| Obstáculo | Quem resolve |
|---|---|
| Gelo | Mago do Fogo derrete |
| Parede rachada | Guerreiro e Mago do Raio quebram |
| Fogueira | Maga da Água apaga; o Mago do Fogo passa sem se queimar |
| Diamante no alto | Maga da Terra sobe com degraus de pedra; a Maga da Água sobe num morcego preso na bolha |

## Progresso salvo

O jogo guarda no aparelho os diamantes encontrados em cada fase (somando todos os heróis), as fases concluídas (troféu no cartão), o último herói e a última fase escolhidos e se a música está ligada. Diamantes já encontrados aparecem transparentes na fase. Desinstalar o app apaga o progresso.

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

## Editando as fases

As fases ficam em `assets/tiles/fase1.tmx`, `fase2.tmx` e `fase3.tmx`, no formato do [Tiled](https://www.mapeditor.org/) (gratuito):

- camada **terreno**: blocos em que o herói pisa e bate;
- camada **decoracao**: plantas, placas e árvores, sem colisão;
- camada **objetos**: retângulos com nome `inicio`, `moeda`, `diamante`, `mola`, `checkpoint`, `chegada`, um inimigo (`slime`, `slime_fogo`, `morcego`, `golem`) ou um obstáculo (`gelo`, `rachada`, `fogueira`).

Abra o arquivo no Tiled, desenhe com os blocos de `blocos.png`, salve e rode o jogo de novo.

As fases foram geradas por `ferramentas/gerar_fases.py`. Rodar o script de novo **sobrescreve** as edições feitas no Tiled. Para criar uma fase nova, acrescente uma função no script e uma entrada em `lib/jogo/fases.dart`.

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
    obstaculos.dart    gelo, parede rachada, fogueira e diamante
    fases.dart         lista das fases (mapa, fundo e cor do céu)
    itens.dart         moeda, mola e bandeira
    controle.dart      toque, teclado, controle remoto e gamepad de um jogador
    entrada_de_controles.dart  eventos dos controles vindos do Android, com o número do dispositivo
  telas/               escolha do herói, placar, botões de toque, vitória e derrota
assets/
  images/ tiles/ audio/
```

Feito com [Flame](https://flame-engine.org/) e [flame_tiled](https://pub.dev/packages/flame_tiled).

## Créditos

Arte e efeitos sonoros: [Kenney](https://kenney.nl) — pacotes *Pixel Platformer*, *Tiny Dungeon*, *Digital Audio* e *Music Jingles*, licença CC0 (`assets/LICENCA-KENNEY*.txt`). Os magos, as magas, o slime de fogo e o golem são versões recoloridas dos personagens do *Tiny Dungeon*.

Música de fundo: composição original deste projeto.
