# Aventura

Jogo de plataforma em Flutter feito para os meus filhos: escolha um herói com um poder (espada, raio, fogo, terra ou água), corra, pule, pegue as moedas, derrote os monstros e chegue até a bandeira.

Roda em celular e tablet Android, em TV box Android (com controle remoto ou controle de videogame) e no navegador.

**Jogar no navegador:** https://jean8791.github.io/aventura/ · **Baixar para Android:** [Aventura.apk](https://github.com/Jean8791/aventura/releases/latest/download/Aventura.apk)

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
- Para pausar: botão ⏸ no canto de cima, botão Voltar do celular ou do controle remoto, ou Start no controle Bluetooth. Na pausa dá para continuar, trocar de herói ou escolher outra fase.

## Dois jogadores

Na tela inicial, escolha **2 jogadores**. Cada jogador aperta um botão no próprio controle para entrar (controle Bluetooth, controle remoto da TV box ou teclado) e depois escolhe o seu herói.

- No teclado, dá para jogar os dois: o jogador que entrar com W, A, S ou D usa essas teclas (W pula, S usa o poder); o outro usa as setas.
- A câmera fica entre os dois, e ninguém sai da tela: um precisa esperar o outro.
- Cada um tem os seus corações. Quem cai num buraco reaparece ao lado do companheiro. Quem perde todos os corações desmaia por 3 segundos e volta ao lado do companheiro com os corações cheios. A fase só recomeça se os dois desmaiarem.
- Moedas e diamantes são do time.

Para saber de qual controle veio cada botão, o app lê os eventos no Android (`MainActivity.kt`) e os envia ao Flutter pelo canal `aventura/controles` com a identificação do dispositivo (o descritor do Android, que não muda quando um controle Bluetooth reconecta). Durante a partida em dupla, o app trata sozinho o direcional e a alavanca de cada controle, para o Android não misturar as setas de um controle com as do outro.

No navegador, o modo de 2 jogadores funciona com o teclado: um jogador nas setas e o outro em W, A, S, D.

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
| 4. Caverna de Cristal | caverna | plataformas que se movem, teto baixo, gelo, parede rachada, fogueira, corações |
| 5. Covil do Feiticeiro | arena | o chefão |

### O chefão: Feiticeiro das Sombras

Ele flutua lançando orbes (dá para desviar ou destruí-los com qualquer poder), treme como aviso e dá uma investida pelo chão. Quando bate na parede, fica tonto por alguns segundos: é a hora de atacar, porque tonto ele leva dano dobrado. Todo herói consegue machucá-lo, inclusive pulando em cima dele. A luta tem música própria.

A luta tem 3 estágios. Quando a vida zera, ele se transforma, volta com a vida cheia, solta um coração e fica mais agressivo:

| Estágio | Visual | Ataques |
|---|---|---|
| 1. Feiticeiro | roxo | 1 orbe por vez, investida, chama slime |
| 2. Bravo | vermelho, maior, aura laranja | 2 orbes em V, chuva de orbes, investida mais rápida, chama slime de fogo |
| 3. Furioso | vinho, maior ainda, aura vermelha | 3 orbes em leque, chuva maior, investida dupla, fica tonto menos tempo, chama slime de fogo e morcego |

Se os heróis perderem, o estágio e o dano que ele já levou continuam valendo.

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

### Versão web

```bash
fvm flutter build web --release --base-href /aventura/
```

A cada push na `main`, o GitHub Actions (`.github/workflows/pages.yml`) compila a versão web e publica no GitHub Pages.

### Instalar na TV box

```bash
fvm flutter build apk --release
adb connect <ip-da-tv-box>
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Sem `adb`, dá para copiar o `app-release.apk` para um pendrive e instalar pelo gerenciador de arquivos da TV box (é preciso permitir apps de fontes desconhecidas). O jogo aparece no menu da TV como **Aventura**.

## Editando as fases

As fases ficam em `assets/tiles/fase1.tmx` a `fase5.tmx`, no formato do [Tiled](https://www.mapeditor.org/) (gratuito):

- camada **terreno**: blocos em que o herói pisa e bate;
- camada **decoracao**: plantas, placas e árvores, sem colisão;
- camada **objetos**: retângulos com nome `inicio`, `moeda`, `diamante`, `coracao`, `mola`, `checkpoint`, `chegada`, um inimigo (`slime`, `slime_fogo`, `morcego`, `golem`), um obstáculo (`gelo`, `rachada`, `fogueira`), uma plataforma móvel (`plataforma_h` ou `plataforma_v`, que vai e volta dentro do retângulo) ou `chefe` (o retângulo é a arena).

Abra o arquivo no Tiled, desenhe com os blocos de `blocos.png`, salve e rode o jogo de novo.

As fases foram geradas por `ferramentas/gerar_fases.py`. Rodar o script de novo **sobrescreve** as edições feitas no Tiled. Para criar uma fase nova, acrescente uma função no script e uma entrada em `lib/jogo/fases.dart`.

## Música

As músicas são composições originais, geradas por `ferramentas/gerar_musica.py` (Python puro, sem dependências): melodia 8-bit, baixo e bateria, com 16 compassos que repetem sem emenda. A das fases é em Dó maior a 150 BPM; a do chefão, em Lá menor a 168 BPM. Para mudar, edite `MELODIA`/`ACORDES` (ou `MELODIA_CHEFE`/`ACORDES_CHEFE`) no script e rode:

```bash
python3 ferramentas/gerar_musica.py
```

## Ícone

O ícone do app e da versão web é gerado por `ferramentas/gerar_icone.py` (precisa do Pillow) a partir do sprite do Guerreiro.

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
    chefe.dart         Feiticeiro das Sombras e seus orbes
    alvo.dart          o que pode receber golpe dos poderes (inimigos, chefe, orbes)
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
