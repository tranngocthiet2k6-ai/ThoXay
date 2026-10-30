"""Check the native Office deliverable and its defense script after rendering."""
import ast
import re
import zipfile
import xml.etree.ElementTree as E
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NS = {
    'p': 'http://schemas.openxmlformats.org/presentationml/2006/main',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
}
source = ast.parse((ROOT / 'scripts/build-defense-slides.py').read_text(encoding='utf-8'))
notes = next(ast.literal_eval(n.value) for n in source.body if isinstance(n, ast.Assign)
             and any(isinstance(t, ast.Name) and t.id == 'notes' for t in n.targets))
normalize = lambda value: ' '.join(value.split())
with zipfile.ZipFile(ROOT / 'docs/SLIDE_BAO_VE_DO_AN.pptx') as package:
    names = package.namelist()
    for name in names:
        if name.endswith(('.xml', '.rels')):
            E.fromstring(package.read(name))
    presentation = E.fromstring(package.read('ppt/presentation.xml'))
    assert len(presentation.findall('p:sldIdLst/p:sldId', NS)) == len(notes) == 15
    assert presentation.find('p:sldSz', NS).attrib['cx'] == '12192000'
    assert presentation.find('p:sldSz', NS).attrib['cy'] == '6858000'
    slide_parts = [n for n in names if re.fullmatch(r'ppt/slides/slide\d+\.xml', n)]
    note_parts = [n for n in names if re.fullmatch(r'ppt/notesSlides/notesSlide\d+\.xml', n)]
    assert len(slide_parts) == len(note_parts) == 15
    for index in range(1, 16):
        note = E.fromstring(package.read(f'ppt/notesSlides/notesSlide{index}.xml'))
        body = [s for s in note.findall('.//p:sp', NS)
                if (p := s.find('p:nvSpPr/p:nvPr/p:ph', NS)) is not None
                and p.attrib.get('type') == 'body']
        assert len(body) == 1
        actual = ' '.join(n.text or '' for n in body[0].findall('.//a:t', NS))
        assert normalize(actual) == normalize(notes[index-1]), f'Notes mismatch on {index}'
        slide = E.fromstring(package.read(f'ppt/slides/slide{index}.xml'))
        for shape in slide.findall('.//p:sp', NS) + slide.findall('.//p:pic', NS):
            transform = shape.find('p:spPr/a:xfrm', NS)
            if transform is None:
                continue
            off = transform.find('a:off', NS).attrib
            size = transform.find('a:ext', NS).attrib
            x, y, w, h = (int(off['x']), int(off['y']), int(size['cx']), int(size['cy']))
            assert min(x, y, w, h) >= 0 and x+w <= 12192000 and y+h <= 6858000
        fonts = [n.attrib.get('typeface') for n in slide.findall('.//a:rPr/a:latin', NS)]
        assert fonts and set(fonts) == {'Arial'}
    images = [n for n in names if n.startswith('ppt/media/')]
    assert len(images) >= 12
script = (ROOT / 'docs/KICH_BAN_DEMO_VA_HOI_DAP.md').read_text(encoding='utf-8')
questions = [int(n) for n in re.findall(r'^### Câu (\d+)', script, re.M)]
assert questions == list(range(1, 21)), questions
assert len(re.findall(r'^### Bước \d+', script, re.M)) == 8
print('Defense validated: 15 slides, 15 complete Speaker Notes, 16:9, editable Arial text, '
      f'{len(images)} embedded images, no off-canvas objects, 8 demo steps and 20 Q&A.')
