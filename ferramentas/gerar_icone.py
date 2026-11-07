from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
CEU = (116, 200, 236, 255)
GRAMA = (62, 190, 96, 255)
GRAMA_ESCURA = (40, 150, 80, 255)
TERRA = (200, 120, 80, 255)
TERRA_ESCURA = (170, 95, 62, 255)


def desenhar():
    tela = Image.new('RGBA', (24, 24), CEU)
    for x in range(24):
        tela.putpixel((x, 19), GRAMA)
        tela.putpixel((x, 20), GRAMA_ESCURA if x % 3 == 0 else GRAMA)
        for y in range(21, 24):
            tela.putpixel((x, y), TERRA_ESCURA if (x + y) % 5 == 0 else TERRA)
    heroi = Image.open(RAIZ / 'assets/images/herois/guerreiro.png').convert('RGBA')
    tela.alpha_composite(heroi, (4, 3))
    diamante = Image.open(RAIZ / 'assets/images/diamante.png').convert('RGBA')
    diamante = diamante.crop(diamante.getbbox()).resize((7, 7), Image.NEAREST)
    tela.alpha_composite(diamante, (16, 3))
    return tela


def salvar(tela, caminho, lado):
    caminho.parent.mkdir(parents=True, exist_ok=True)
    tela.resize((lado, lado), Image.NEAREST).save(caminho)


def main():
    tela = desenhar()
    web = RAIZ / 'web'
    salvar(tela, web / 'favicon.png', 32)
    for lado in (192, 512):
        salvar(tela, web / f'icons/Icon-{lado}.png', lado)
        salvar(tela, web / f'icons/Icon-maskable-{lado}.png', lado)
    res = RAIZ / 'android/app/src/main/res'
    for pasta, lado in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        salvar(tela, res / f'mipmap-{pasta}/ic_launcher.png', lado)


if __name__ == '__main__':
    main()
