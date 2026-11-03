"""Export platform sizes from the approved RGBA logo; no logo redrawing."""
import json
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
logo = Image.open(ROOT / 'branding/logo_xay_transparent.png').convert('RGBA')
assert logo.getextrema()[3][0] == 0, 'Master logo must preserve transparency'

def save(image, relative):
    target = ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)

def icon(size):
    canvas = Image.new('RGBA', (size, size), 'white')
    mark = ImageOps.contain(logo, (round(size * .78), round(size * .78)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(mark, ((size - mark.width) // 2, (size - mark.height) // 2))
    return canvas.convert('RGB')

save(icon(1024), 'branding/app_icon.png')
for folder in ['mobile_app/assets/branding', 'mobile_app/web/branding', 'src/main/resources/static/branding']:
    save(logo, folder + '/logo_xay_transparent.png')
    save(icon(512), folder + '/app_icon.png')
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    save(icon(size), f'mobile_app/android/app/src/main/res/mipmap-{density}/ic_launcher.png')
ios = ROOT / 'mobile_app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((ios/'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
    save(icon(size), str((ios/entry['filename']).relative_to(ROOT)))
for size in [192,512]:
    for name in [f'Icon-{size}.png', f'Icon-maskable-{size}.png']:
        save(icon(size), 'mobile_app/web/icons/' + name)
save(icon(64), 'mobile_app/web/favicon.png')
for folder in ['mobile_app/web','src/main/resources/static']:
    target = ROOT / folder / 'favicon.ico'
    icon(256).save(target, format='ICO', sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
preview = Image.new('RGBA',logo.size,'white');preview.alpha_composite(logo)
save(preview.convert('RGB'), '.local/xay/logo-on-white.png')
print('Xây logo copied; Android/iOS/Web icons and ICO exported. Package IDs unchanged.')
