"""Validate coverage and package structure of the deliverable, not just its text."""
import hashlib,json,re,zipfile,xml.etree.ElementTree as E
from pathlib import Path
root=Path(__file__).resolve().parents[1]
inventory=json.loads((root/'docs/PROJECT_INVENTORY.json').read_text(encoding='utf-8'))
md=(root/'docs/BAO_CAO_DO_AN.md').read_text(encoding='utf-8')
schema=(root/'schema.sql').read_text(encoding='utf-8')
assert set(re.findall(r'CREATE TABLE IF NOT EXISTS (\w+)',schema))==set(inventory['tables'])
assert len({(r['method'],r['path']) for r in inventory['routes']})==111
assert inventory['counts']['rest']==90 and inventory['counts']['mvc']==21
assert sum(len(t['columns']) for t in inventory['tables'].values())==256
assert hashlib.sha256((root/'schema.sql').read_bytes()).hexdigest()==inventory['schema_sha256']
for file,digest in inventory['controller_sha256'].items():assert hashlib.sha256((root/file).read_bytes()).hexdigest()==digest
for name,t in inventory['tables'].items():
    assert 'Bảng '+name in md
    for col in t['columns']:assert '| '+col['name']+' | '+col['type']+' |' in md
for r in inventory['routes']:assert '| '+r['method']+' | '+r['path']+' |' in md
blocks=list(re.finditer(r'<!-- diagram:([\w-]+) -->\s*```mermaid\s*\n([\s\S]*?)```',md))
manifest=json.loads((root/'docs/diagrams/manifest.json').read_text(encoding='utf-8'))
assert len(blocks)==len(manifest)==12
for b,m in zip(blocks,manifest):
    assert b[1]==m['name']
    assert hashlib.sha256(b[2].encode()).hexdigest()==m['sourceSha256']
    assert hashlib.sha256((root/m['file']).read_bytes()).hexdigest()==m['pngSha256']
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
with zipfile.ZipFile(root/'docs/BAO_CAO_DO_AN.docx') as z:
    for name in z.namelist():
        if name.endswith(('.xml','.rels')):E.fromstring(z.read(name))
    doc=E.fromstring(z.read('word/document.xml'));styles=E.fromstring(z.read('word/styles.xml'))
    assert len([n for n in z.namelist() if n.startswith('word/media/')])==12
    tables=doc.findall('.//w:tbl',ns);assert len(tables)==65
    for table in tables:
        borders=table.find('w:tblPr/w:tblBorders',ns);assert borders is not None and len(borders)==6
        assert table.find('w:tr/w:trPr/w:tblHeader',ns) is not None
    default=styles.find('w:docDefaults/w:rPrDefault/w:rPr',ns)
    assert default.find('w:sz',ns).attrib['{'+ns['w']+'}val']=='26'
    assert default.find('w:rFonts',ns).attrib['{'+ns['w']+'}ascii']=='Times New Roman'
    assert styles.find('w:docDefaults/w:pPrDefault/w:pPr/w:spacing',ns).attrib['{'+ns['w']+'}line']=='360'
print('Report validated: 30 tables / 256 columns / 111 mappings / 12 PNGs and embedded diagrams / 65 bordered tables; Times New Roman 13 and 1.5 line spacing.')
