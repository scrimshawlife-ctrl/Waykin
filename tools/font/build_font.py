from pathlib import Path
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

UPEM=1000
ASCENT=820
DESCENT=-180
CELL=110
X0=70
Y0=70
BAR=88
ADV=720
FAMILY='Waykin Display'
PS='WaykinDisplay-Regular'

PATTERNS={
'A':["01110","10001","10001","11111","10001","10001","10001"],
'B':["11110","10001","10001","11110","10001","10001","11110"],
'C':["01111","10000","10000","10000","10000","10000","01111"],
'D':["11110","10001","10001","10001","10001","10001","11110"],
'E':["11111","10000","10000","11110","10000","10000","11111"],
'F':["11111","10000","10000","11110","10000","10000","10000"],
'G':["01111","10000","10000","10111","10001","10001","01111"],
'H':["10001","10001","10001","11111","10001","10001","10001"],
'I':["11111","00100","00100","00100","00100","00100","11111"],
'J':["00111","00010","00010","00010","10010","10010","01100"],
'K':["10001","10010","10100","11000","10100","10010","10001"],
'L':["10000","10000","10000","10000","10000","10000","11111"],
'M':["10001","11011","10101","10101","10001","10001","10001"],
'N':["10001","11001","10101","10011","10001","10001","10001"],
'O':["01110","10001","10001","10001","10001","10001","01110"],
'P':["11110","10001","10001","11110","10000","10000","10000"],
'Q':["01110","10001","10001","10001","10101","10010","01101"],
'R':["11110","10001","10001","11110","10100","10010","10001"],
'S':["01111","10000","10000","01110","00001","00001","11110"],
'T':["11111","00100","00100","00100","00100","00100","00100"],
'U':["10001","10001","10001","10001","10001","10001","01110"],
'V':["10001","10001","10001","10001","10001","01010","00100"],
'W':["10001","10001","10001","10101","10101","10101","01010"],
'X':["10001","10001","01010","00100","01010","10001","10001"],
'Y':["10001","10001","01010","00100","00100","00100","00100"],
'Z':["11111","00001","00010","00100","01000","10000","11111"],
'0':["01110","10001","10011","10101","11001","10001","01110"],
'1':["00100","01100","00100","00100","00100","00100","01110"],
'2':["01110","10001","00001","00010","00100","01000","11111"],
'3':["11110","00001","00001","01110","00001","00001","11110"],
'4':["00010","00110","01010","10010","11111","00010","00010"],
'5':["11111","10000","10000","11110","00001","00001","11110"],
'6':["01110","10000","10000","11110","10001","10001","01110"],
'7':["11111","00001","00010","00100","01000","01000","01000"],
'8':["01110","10001","10001","01110","10001","10001","01110"],
'9':["01110","10001","10001","01111","00001","00001","01110"],
'.':["00000","00000","00000","00000","00000","00110","00110"],
':':["00000","00110","00110","00000","00110","00110","00000"],
'-':["00000","00000","00000","11111","00000","00000","00000"],
"'":["00110","00110","00100","00000","00000","00000","00000"],
'&':["01100","10010","10100","01000","10101","10010","01101"],
}

def rect(pen,x,y,w,h):
    pen.moveTo((x,y)); pen.lineTo((x+w,y)); pen.lineTo((x+w,y+h)); pen.lineTo((x,y+h)); pen.closePath()

def glyph_for(pattern):
    pen=TTGlyphPen(None)
    for row,line in enumerate(pattern):
        for col,v in enumerate(line):
            if v=='1':
                x=X0+col*CELL
                y=Y0+(6-row)*CELL
                inset=8 if (row+col)%3==0 else 0
                rect(pen,x+inset,y+inset,BAR-2*inset,BAR-2*inset)
    return pen.glyph()

def empty(): return TTGlyphPen(None).glyph()

def notdef():
    pen=TTGlyphPen(None); rect(pen,80,40,520,720); rect(pen,170,130,340,540); return pen.glyph()

def build(out:Path):
    glyph_order=['.notdef','space']+[f'uni{ord(c):04X}' for c in PATTERNS]
    glyphs={'.notdef':notdef(),'space':empty()}
    metrics={'.notdef':(700,40),'space':(320,0)}
    cmap={32:'space'}
    for c,p in PATTERNS.items():
        name=f'uni{ord(c):04X}'
        glyphs[name]=glyph_for(p)
        metrics[name]=(ADV,40)
        cmap[ord(c)]=name
    fb=FontBuilder(UPEM,isTTF=True)
    fb.setupGlyphOrder(glyph_order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=ASCENT,descent=DESCENT,lineGap=0)
    fb.setupOS2(sTypoAscender=ASCENT,sTypoDescender=DESCENT,sTypoLineGap=0,usWinAscent=ASCENT,usWinDescent=abs(DESCENT),fsType=0,sxHeight=520,sCapHeight=760,usWeightClass=500,usWidthClass=5)
    fb.setupNameTable({'familyName':FAMILY,'styleName':'Regular','uniqueFontIdentifier':'WaykinDisplay-Regular-v0.1','fullName':'Waykin Display Regular','psName':PS,'version':'Version 0.1'})
    fb.setupPost(keepGlyphNames=False)
    fb.setupMaxp()
    fb.setupHead(created=2082844800, modified=2082844800)
    out.parent.mkdir(parents=True,exist_ok=True)
    fb.save(out)

def validate(path:Path):
    f=TTFont(path)
    required=set(ord(c) for c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.:-\'& ')
    cmap={cp for table in f['cmap'].tables for cp in table.cmap}
    missing=sorted(required-cmap)
    assert not missing, missing
    assert f['name'].getDebugName(6)==PS
    assert f['OS/2'].fsType==0
    assert len(f.getGlyphOrder())==2+len(PATTERNS)
    print({'font':str(path),'glyphs':len(f.getGlyphOrder()),'postscript':f['name'].getDebugName(6),'fsType':f['OS/2'].fsType,'missing':missing})

if __name__=='__main__':
    out=Path(__file__).resolve().parents[2]/'App/Resources/Fonts/WaykinDisplay-Regular.ttf'
    build(out)
    validate(out)
