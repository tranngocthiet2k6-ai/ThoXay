"""Manual report template branding. Called only by rebuild-defense.ps1 -Rebuild."""
import hashlib,json,re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def display_brand(text):
    # Preserve repository URLs, filenames, namespaces and occupational labels.
    return re.sub(r'(?<![A-Za-z0-9_/.\\-])ThoXay(?![A-Za-z0-9_./\\-])','Xây',text)

paths=[ROOT/'docs/BAO_CAO_DO_AN.md',ROOT/'docs/KICH_BAN_DEMO_VA_HOI_DAP.md',
       ROOT/'docs/TAI_KHOAN_VA_LINK_DEMO.md',ROOT/'docs/BAN_DO_MO_CODE_NHANH.md',
       ROOT/'00_BAO_VE_DO_AN/README.md',ROOT/'00_BAO_VE_DO_AN/HUONG_DAN_WORKSPACE.md']
paths.append(ROOT/'docs/figma_screens/README.md')
for p in paths:
    if not p.exists():continue
    text=display_brand(p.read_text(encoding='utf-8'))
    text=text.replace('131 Backend','134 Backend').replace('119 Flutter','120 Flutter').replace('8 Python','9 Python').replace('8 test bảo vệ seed Python','9 test bảo vệ seed Python')
    text=text.replace('20 ảnh giao diện thực thi DEMO','16 ảnh giao diện chính DEMO').replace('20 PNG chụp giao diện DEMO','16 PNG giao diện chính DEMO')
    p.write_text(text,encoding='utf-8')
manifest=ROOT/'docs/figma_screens/manifest.json'
items=json.loads(manifest.read_text(encoding='utf-8'))
assert len(items)==20,'Capture all twenty views before exporting the defense pack'
for item in items:
    assert hashlib.sha256((manifest.parent/item['file']).read_bytes()).hexdigest()==item['sha256'],item['file']
    item['brand']='Xây'
    item['brandLogoSha256']=hashlib.sha256((ROOT/'branding/logo_xay_transparent.png').read_bytes()).hexdigest()
manifest.write_text(json.dumps(items,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Xây manual templates prepared; 16 primary views plus 4 supplementary views verified.')
