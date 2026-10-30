"""Deterministic OOXML export. No cloud service or user data leaves the machine."""
import io,json,re,zipfile
from pathlib import Path
from xml.sax.saxutils import escape
from PIL import Image
from markdown_it import MarkdownIt

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/BAO_CAO_DO_AN.docx'
NS='http://schemas.openxmlformats.org/wordprocessingml/2006/main'
rels=[];media={};body=[];image_index=0
def text(value):return escape(str(value))
def run(value,bold=False,italic=False,color=None,size=None):
    props='<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="Times New Roman"/>'
    if bold:props+='<w:b/>'
    if italic:props+='<w:i/>'
    if color:props+=f'<w:color w:val="{color}"/>'
    props+=f'<w:sz w:val="{size or 26}"/><w:szCs w:val="{size or 26}"/>'
    return f'<w:r><w:rPr>{props}</w:rPr><w:t xml:space="preserve">{text(value)}</w:t></w:r>'
def inline(children,bold=False,color=None):
    result=[];b=bold;i=False
    for c in children or []:
        if c.type=='strong_open':b=True
        elif c.type=='strong_close':b=bold
        elif c.type=='em_open':i=True
        elif c.type=='em_close':i=False
        elif c.type in ('text','code_inline','softbreak','hardbreak'):
            value=' ' if c.type.endswith('break') else c.content
            if c.type=='code_inline':value=value.replace('_','_\u200b').replace('/','/\u200b')
            result.append(run(value,b,i,color))
    return ''.join(result)
def para(content='',style='Normal',center=False,keep=False,pagebreak=False):
    props=f'<w:pStyle w:val="{style}"/>'
    if center:props+='<w:jc w:val="center"/>'
    if keep:props+='<w:keepNext/>'
    if pagebreak:props+='<w:pageBreakBefore/>'
    return f'<w:p><w:pPr>{props}</w:pPr>{content}</w:p>'
def table(rows):
    columns=len(rows[0]);widths={2:[3400,5671],3:[2300,3200,3571],4:[2050,1800,2400,2821],5:[700,1800,2200,2200,2171]}.get(columns,[9071//columns]*columns)
    header=rows[0][0][0]
    if header=='Cột':widths=[2350,1850,2050,2821]
    elif header=='HTTP':widths=[1200,4300,3571]
    elif header=='Thư viện':widths=[2400,1600,5071]
    elif header in ('Công nghệ','Thành phần'):widths=[2200,3500,3371]
    elif header=='Nhóm':widths=[1500,3900,3671]
    elif header=='STT':widths=[800,1800,3500,2971]
    borders=''.join(f'<w:{s} w:val="single" w:sz="6" w:color="D9D9D9"/>' for s in ['top','left','bottom','right','insideH','insideV'])
    result=f'<w:tbl><w:tblPr><w:tblW w:w="9071" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders>{borders}</w:tblBorders><w:tblCellMar><w:top w:w="90" w:type="dxa"/><w:left w:w="100" w:type="dxa"/><w:bottom w:w="90" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>'+''.join(f'<w:gridCol w:w="{w}"/>' for w in widths)+'</w:tblGrid>'
    for ri,row in enumerate(rows):
        result+='<w:tr><w:trPr><w:cantSplit/>'+('<w:tblHeader/>' if ri==0 else '')+'</w:trPr>'
        for ci,(label,children) in enumerate(row):
            fill='E2E8F0' if ri==0 else 'F8FAFC' if ri%2==0 else 'FFFFFF'
            result+=f'<w:tc><w:tcPr><w:tcW w:w="{widths[ci]}" w:type="dxa"/><w:shd w:fill="{fill}"/><w:vAlign w:val="center"/></w:tcPr>'
            if ri>0 and header=='Cột' and ci==1:
                label=label.replace('character varying','varchar').replace('timestamp with time zone','timestamptz').replace('timestamp without time zone','timestamp')
                content=run(label)
            elif ri>0 and header=='Cột' and ci==0:content=run(label.replace('_','_\u200b'))
            else:content=inline(children,bold=ri==0)
            result+=para(content,'TableText',center=header in ('HTTP','STT') and ci==0,keep=ri==0)+'</w:tc>'
        result+='</w:tr>'
    return result+'</w:tbl>'+para()
def figure(name):
    global image_index
    image_index+=1;filename=name+'.png';data=(ROOT/'docs/diagrams'/filename).read_bytes();media[filename]=data
    rid='rIdImage'+str(image_index);rels.append((rid,'image','media/'+filename))
    with Image.open(io.BytesIO(data)) as img:w,h=img.size
    scale=min(16.0/w,18.5/h);cx=int(w*scale*360000);cy=int(h*scale*360000)
    drawing=f'''<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="{cx}" cy="{cy}"/><wp:docPr id="{image_index}" name="{name}" descr="Sơ đồ {name}"/><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="{image_index}" name="{filename}"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>'''
    return para(drawing,style='Figure',center=True,keep=True)

tokens=MarkdownIt('commonmark').enable('table').parse((ROOT/'docs/BAO_CAO_DO_AN.md').read_text(encoding='utf-8'))
i=0;pending_diagram=None;heading_count=0;suppress_toc=False;list_depth=0
while i<len(tokens):
    t=tokens[i]
    if t.type=='html_block':
        m=re.search(r'diagram:([\w-]+)',t.content)
        if m:pending_diagram=m.group(1)
    elif t.type=='heading_open':
        label=tokens[i+1].content;level=int(t.tag[1]);heading_count+=1
        if label=='Mục lục':
            body.append(para(run(label,True,size=32),'TOCHeading',keep=True))
            body.append(para('<w:fldSimple w:instr="TOC \\o &quot;1-2&quot; \\h \\z \\u"><w:r><w:t>Cập nhật mục lục trong Microsoft Word</w:t></w:r></w:fldSimple>'))
            suppress_toc=True
        else:
            suppress_toc=False
            style='Title' if heading_count==1 else 'Subtitle' if heading_count==2 else 'Heading'+str(min(level,3))
            size=40 if style=='Title' else 32 if level<=2 else 28
            content=run(label,True,size=size)
            body.append(para(content,style,center=style in ('Title','Subtitle'),keep=True,pagebreak=label.startswith('Chương ')))
        i+=2
    elif not suppress_toc and t.type=='paragraph_open':
        follows_table=i+3<len(tokens) and tokens[i+3].type=='table_open'
        body.append(para((run('• ') if list_depth else '')+inline(tokens[i+1].children),'ListText' if list_depth else 'Normal',keep=follows_table));i+=2
    elif not suppress_toc and t.type=='table_open':
        rows=[];row=[];i+=1
        while tokens[i].type!='table_close':
            if tokens[i].type=='tr_open':row=[]
            elif tokens[i].type=='inline':row.append((tokens[i].content,tokens[i].children))
            elif tokens[i].type=='tr_close':rows.append(row)
            i+=1
        body.append(table(rows))
    elif t.type in ('bullet_list_open','ordered_list_open'):list_depth+=1
    elif t.type in ('bullet_list_close','ordered_list_close'):list_depth-=1
    elif not suppress_toc and t.type=='fence':
        if t.info=='mermaid':
            if not pending_diagram:raise ValueError('Missing diagram marker')
            body.append(figure(pending_diagram));pending_diagram=None
        else:
            for line in t.content.rstrip().splitlines():body.append(para(run(line.replace('_','_\u200b')),'Code'))
    i+=1

styles=f'''<w:styles xmlns:w="{NS}"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="Times New Roman"/><w:sz w:val="26"/><w:lang w:val="vi-VN"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="100" w:line="360" w:lineRule="auto"/><w:widowControl/></w:pPr></w:pPrDefault></w:docDefaults>'''
for sid in ['Normal','Title','Subtitle','Heading1','Heading2','Heading3','TableText','ListText','Code','Figure','TOCHeading']:
    level={'Heading1':0,'Heading2':1,'Heading3':2}.get(sid)
    props='<w:spacing w:line="360" w:lineRule="auto" w:after="100"/>'
    if level is not None:props+=f'<w:keepNext/><w:spacing w:before="220" w:after="120"/><w:outlineLvl w:val="{level}"/>'
    if sid=='TableText':props='<w:spacing w:line="360" w:lineRule="auto" w:after="0"/>'
    if sid=='Figure':props='<w:spacing w:line="240" w:lineRule="auto" w:after="100"/>'
    if sid=='ListText':props+='<w:ind w:left="280" w:hanging="280"/>'
    styles+=f'<w:style w:type="paragraph" w:styleId="{sid}"'+(' w:default="1"' if sid=='Normal' else '')+'>'+f'<w:name w:val="{sid}"/>'+('' if sid=='Normal' else '<w:basedOn w:val="Normal"/>')+f'<w:pPr>{props}</w:pPr><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:color w:val="000000"/><w:sz w:val="26"/></w:rPr></w:style>'
styles+='</w:styles>'
section='<w:sectPr><w:headerReference w:type="default" r:id="rIdHeader"/><w:footerReference w:type="default" r:id="rIdFooter"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1701" w:header="567" w:footer="567"/></w:sectPr>'
document=f'''<w:document xmlns:w="{NS}" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>{''.join(body)}{section}</w:body></w:document>'''
relationship='<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
for rid,kind,path in [('rIdStyles','styles','styles.xml'),('rIdSettings','settings','settings.xml'),('rIdHeader','header','header1.xml'),('rIdFooter','footer','footer1.xml')]+rels:
    relationship+=f'<Relationship Id="{rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/{kind}" Target="{path}"/>'
relationship+='</Relationships>'
types='<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/>'
for name,kind in [('document','document.main'),('styles','styles'),('settings','settings'),('header1','header'),('footer1','footer')]:types+=f'<Override PartName="/word/{name}.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.{kind}+xml"/>'
types+='</Types>'
files={'[Content_Types].xml':types,'_rels/.rels':'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>',
'word/document.xml':document,'word/styles.xml':styles,'word/_rels/document.xml.rels':relationship,'word/settings.xml':f'<w:settings xmlns:w="{NS}"><w:updateFields w:val="true"/><w:defaultTabStop w:val="720"/></w:settings>',
'word/header1.xml':f'<w:hdr xmlns:w="{NS}">'+para(run('ThoXay   Báo cáo đồ án tốt nghiệp',size=20))+'</w:hdr>',
'word/footer1.xml':f'<w:ftr xmlns:w="{NS}">'+para('<w:fldSimple w:instr="PAGE"/>',center=True)+'</w:ftr>'}
with zipfile.ZipFile(OUT,'w',zipfile.ZIP_DEFLATED) as z:
    for name,value in files.items():z.writestr(name,'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+value)
    for name,value in media.items():z.writestr('word/media/'+name,value)
print('DOCX exported:',len(media),'embedded diagrams;',sum(t.type=='table_open' for t in tokens),'tables')
