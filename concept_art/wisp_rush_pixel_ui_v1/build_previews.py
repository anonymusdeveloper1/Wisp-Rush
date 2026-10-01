"""Build labeled review sheets. Labels appear only in previews, never in component PNGs."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
SRC=ROOT/'components'
OUT=ROOT/'previews'
OUT.mkdir(exist_ok=True)
META={Path(x['file']).stem:x for x in json.loads((ROOT/'components.json').read_text(encoding='utf-8'))['components']}
try:
    FONT=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',21)
    TITLE=ImageFont.truetype('C:/Windows/Fonts/consolab.ttf',31)
except OSError:
    FONT=ImageFont.load_default();TITLE=FONT


def nine(im,margins,size):
    l,t,r,b=margins;w,h=im.size;W,H=size
    assert W>=l+r and H>=t+b
    dst=Image.new('RGBA',size)
    xs=[(0,l,0,l),(l,w-r,l,W-r),(w-r,w,W-r,W)]
    ys=[(0,t,0,t),(t,h-b,t,H-b),(h-b,h,H-b,H)]
    for sx0,sx1,dx0,dx1 in xs:
        for sy0,sy1,dy0,dy1 in ys:
            part=im.crop((sx0,sy0,sx1,sy1))
            part=part.resize((dx1-dx0,dy1-dy0),Image.Resampling.NEAREST)
            dst.alpha_composite(part,(dx0,dy0))
    return dst


def board(w,h,title):
    im=Image.new('RGBA',(w,h),(11,17,22,255));d=ImageDraw.Draw(im)
    d.rectangle((0,0,w-1,h-1),outline=(83,96,100,255),width=4)
    d.text((30,20),title,font=TITLE,fill=(250,229,193))
    d.line((30,65,w-30,65),fill=(167,135,104),width=4)
    return im,d


def item(sheet,draw,name,x,y,size=None,label=None):
    data=META[name]; im=Image.open(SRC/(name+'.png')).convert('RGBA')
    if size:
        if 'nine_slice_px' in data:im=nine(im,data['nine_slice_px'],size)
        else:im=im.resize(size,Image.Resampling.NEAREST)
    sheet.alpha_composite(im,(x,y+30))
    draw.text((x,y),label or name,font=FONT,fill=(232,202,160))

menu,d=board(1500,1260,'WISP RUSH  /  PIXEL MENU COMPONENTS')
for k,s in enumerate(['normal','hover','focus','pressed','disabled']):
    item(menu,d,'button_primary_'+s,25+k*295,90,(250,112),f'PRIMARY / {s.upper()}')
    item(menu,d,'button_secondary_'+s,25+k*295,255,(250,96),f'SECONDARY / {s.upper()}')
item(menu,d,'button_danger_normal',25,405,(250,96),'DANGER / NORMAL')
item(menu,d,'button_danger_pressed',320,405,(250,96),'DANGER / PRESSED')
for k,s in enumerate(['normal','focus','disabled']):
    item(menu,d,'icon_tile_'+s,650+k*270,405,(112,112),f'ICON TILE / {s.upper()}')
item(menu,d,'panel_default',25,605,(188,204),'PANEL')
item(menu,d,'panel_banner',255,605,(250,120),'BANNER')
item(menu,d,'panel_card',540,605,(188,252),'CARD')
item(menu,d,'panel_card_selected',760,605,(188,252),'CARD / SELECTED')
item(menu,d,'panel_card_locked',980,605,(188,252),'CARD / LOCKED')
item(menu,d,'panel_crest',1200,605,(196,308),'CREST')
item(menu,d,'slot_normal',25,990,None,'SLOT')
item(menu,d,'slot_selected',180,990,None,'SLOT / SELECTED')
item(menu,d,'slot_disabled',390,990,None,'SLOT / DISABLED')
item(menu,d,'tab_normal',620,990,(190,64),'TAB')
item(menu,d,'tab_active',850,990,(190,64),'TAB / ACTIVE')
item(menu,d,'plate_small',1090,990,(250,64),'VALUE PLATE')
menu.save(OUT/'menu_components.png',optimize=True)

hud,d=board(1500,780,'WISP RUSH  /  PIXEL GAMEPLAY HUD COMPONENTS')
item(hud,d,'hud_counter_plate',40,105,(300,64),'COUNTER / SCORE / CURRENCY')
item(hud,d,'hud_alert_plate',400,105,(300,64),'ALERT / REWARD')
item(hud,d,'hud_health_socket',760,105,None,'SOUL SOCKET')
item(hud,d,'hud_health_full',990,105,None,'SOUL FILLED')
item(hud,d,'icon_tile_normal',1200,105,None,'PAUSE TILE FRAME')
for k,(name,label) in enumerate([
 ('progress_track','TRACK'),('progress_fill_xp','XP / CYAN'),
 ('progress_fill_boss','BOSS / MAGENTA'),('progress_fill_reward','REWARD / AMBER')]):
    item(hud,d,name,35+k*365,265,(320,40),label)
for k,(name,label) in enumerate([
 ('hud_slim_track','SLIM TRACK'),('hud_slim_fill_xp','SLIM XP'),
 ('hud_slim_fill_rush','RUSH / IVORY'),('hud_slim_fill_boss','SLIM BOSS')]):
    item(hud,d,name,35+k*365,395,(320,20),label)
for k,(name,label) in enumerate([
 ('slider_grabber_idle','SLIDER'),('slider_grabber_active','SLIDER / ACTIVE'),
 ('page_diamond_idle','PAGE'),('page_diamond_active','PAGE / ACTIVE'),
 ('page_diamond_locked','PAGE / LOCKED'),('divider','DIVIDER')]):
    item(hud,d,name,35+k*235,535,None,label)
item(hud,d,'ornament_diamond_warm',35,665,None,'WARM SEAL')
item(hud,d,'ornament_diamond_cyan',275,665,None,'CYAN RUNE')
item(hud,d,'ornament_stitches',515,665,None,'STITCHES')
hud.save(OUT/'hud_components.png',optimize=True)

icons,d=board(1200,560,'WISP RUSH  /  TEXT-FREE PIXEL GLYPHS')
names=['play','pause','back','home','lock','settings','shop','trials',
       'daily','stats','rift','currency','health','audio','mute','close']
for k,name in enumerate(names):
    x=20+(k%8)*147;y=105+(k//8)*210
    item(icons,d,'icon_'+name,x,y,(112,112),name.upper())
icons.save(OUT/'icon_components.png',optimize=True)

nav,d=board(1500,720,'WISP RUSH  /  HOME, SHOP AND PORTRAIT PIECES')
for k,state in enumerate(['normal','focus','disabled']):
    item(nav,d,'caption_tile_'+state,30+k*230,105,None,'HOME TILE / '+state.upper())
item(nav,d,'portrait_ring',760,105,None,'PORTRAIT RING')
item(nav,d,'portrait_ring_selected',1090,105,None,'RING / SELECTED')
item(nav,d,'nav_dock',30,405,(680,88),'SHOP TAB DOCK')
item(nav,d,'badge_plate_warm',790,405,(190,40),'WARM BADGE')
item(nav,d,'badge_plate_muted',1050,405,(190,40),'LOCKED BADGE')
nav.save(OUT/'navigation_components.png',optimize=True)
print('review sheets: menu, HUD, icon, and navigation components')
