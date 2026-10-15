import sys
from PIL import Image, ImageDraw, ImageFont
src,dst,title=sys.argv[1:4]
lines=[title,""]+[l[:150] for l in open(src).read().splitlines()]
try: font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",14)
except: font=ImageFont.load_default()
W=max(900,max(len(l) for l in lines)*9+40); H=len(lines)*18+40
im=Image.new("RGB",(W,H),(18,18,24)); d=ImageDraw.Draw(im)
for i,l in enumerate(lines): d.text((20,20+i*18),l,font=font,fill=(255,200,60) if i==0 else ((120,220,140) if l.startswith("=>") else (225,225,225)))
im.save(dst)
