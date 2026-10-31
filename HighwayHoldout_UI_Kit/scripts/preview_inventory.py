"""Tablet inventory composition using reusable assets and editable labels."""
from PIL import Image,ImageDraw
from preview_draw import *

def inventory():
    im=background(1920,1440,155)
    text(im,(64,38),'HIGHWAY HOLDOUT',25,'white','bold')
    text(im,(65,76),'OUTPOST 01',18,'#B6CECA','demi')
    text(im,(1810,55),'DAY 12',25,'white','demi','ra')
    glyph(im,'clock',1826,42,36,'gold')
    surface(im,'ui_panel_light',(48,126,1824,1262))
    text(im,(88,165),'Storage',52,'ink','bold')
    text(im,(90,235),'Supplies & equipment',27,'muted')
    surface(im,'ui_icon_button_normal',(1742,163,88,88),1.5);glyph(im,'close',1768,188,36)
    line(im,(88,292,1828,292))
    text(im,(88,328),'YOUR OUTPOST',18,'muted','bold')
    for i,(g,label) in enumerate([('grid','Overview'),('inventory','Resources'),('build','Equipment'),('map','Town')]):
        y=375+i*98
        if i==1:roundbox(im,(76,y-9,294,y+67),16,'teal')
        glyph(im,g,96,y+10,35,'white' if i==1 else 'muted')
        text(im,(145,y+12),label,25,'white' if i==1 else 'ink','demi' if i==1 else 'medium')
    line(im,(316,324,316,1334))
    text(im,(90,1168),'WAREHOUSE',18,'muted','bold')
    text(im,(90,1205),'68% full',28,'ink','demi')
    roundbox(im,(90,1255,276,1267),6,'surface');roundbox(im,(90,1255,216,1267),6,'teal')
    text(im,(90,1290),'Space to grow.',20,'muted')
    # Category strip and search, above six roomy cards.
    surface(im,'ui_tab_selected',(348,320,220,74),1.4);text(im,(458,354),'All supplies',25,'ink','demi','mm')
    text(im,(612,354),'Food',25,'muted','medium','mm');text(im,(767,354),'Materials',25,'muted','medium','mm')
    surface(im,'ui_search_field',(876,320,374,74),1.4);glyph(im,'search',897,340,30,'muted')
    text(im,(941,337),'Search supplies',24,'muted')
    items=[('food','Canned rations','FOOD','412','selected'),('scrap','Salvaged scrap','MATERIAL','286','normal'),
           ('wood','Timber','MATERIAL','48','normal'),('water','Clean water','SUPPLY','76','normal'),
           ('medicine','Medical kit','EQUIPMENT','8','normal'),('tools','Tool kit','EQUIPMENT','12','normal')]
    for i,(key,title,kind,qty,state) in enumerate(items):
        x=348+(i%3)*306;y=424+(i//3)*374
        surface(im,'ui_item_card_'+state,(x,y,290,350),1.7)
        art(im,'ui_item_'+key,(x+19,y+10,252,226))
        text(im,(x+22,y+239),kind,16,'muted','bold')
        text(im,(x+22,y+266),title,24,'ink','demi')
        text(im,(x+22,y+305),qty,25,'teal','bold')
        if state=='selected':
            roundbox(im,(x+242,y+18,x+272,y+48),15,'teal');glyph(im,'check',x+245,y+21,24,'white')
    text(im,(352,1204),'6 of 14 supply types',23,'muted')
    glyph(im,'sort',1001,1197,30,'muted');text(im,(1044,1203),'By category',23,'ink','medium')
    line(im,(348,1260,1244,1260))
    glyph(im,'info',350,1286,28,'muted');text(im,(394,1286),'Select a supply to see its details.',23,'muted')
    # Selected-item inspector is a calm, fixed-width visual hierarchy.
    roundbox(im,(1296,320,1828,1335),24,'#E8E9DE')
    text(im,(1334,349),'SELECTED SUPPLY',18,'muted','bold')
    roundbox(im,(1334,397,1451,437),18,'#D0E2D6');text(im,(1392,416),'FOOD',18,'teal','bold','mm')
    ImageDraw.Draw(im).ellipse((1386,475,1740,829),fill='#D9E0D3')
    art(im,'ui_item_food',(1325,434,470,425))
    text(im,(1334,861),'Canned rations',36,'ink','bold')
    paragraph(im,(1334,919),'A reliable food reserve for a growing survivor town.',440,24,leading=34)
    line(im,(1334,1018,1790,1018))
    text(im,(1334,1047),'In storage',24,'muted');text(im,(1790,1047),'412 / 600',25,'ink','demi','ra')
    roundbox(im,(1334,1093,1790,1107),7,'#CAD3C7');roundbox(im,(1334,1093,1647,1107),7,'teal')
    text(im,(1334,1138),'Production',24,'muted');text(im,(1790,1138),'+10 / min',25,'teal','demi','ra')
    button(im,(1330,1215,466,88),'View production',size=26)
    save(im,'01_inventory_ipad.png')

if __name__=='__main__':inventory()
