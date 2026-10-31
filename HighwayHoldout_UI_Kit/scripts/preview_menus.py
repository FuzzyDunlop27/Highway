"""Landscape in-game construction drawer and pause menu concepts."""
from preview_draw import *

def construction():
    im=background(1920,886,12);hud(im)
    surface(im,'ui_panel_drawer',(32,365,1856,495))
    text(im,(72,394),'Build your town',38,'ink','bold')
    text(im,(74,445),'Choose a structure, then place it on the map.',23,'muted')
    for i,(label,selected) in enumerate([('Buildings',True),('Defenses',False)]):
        surface(im,'ui_tab_selected' if selected else 'ui_tab_normal',(960+i*215,393,200,76),1.4)
        text(im,(1060+i*215,429),label,24,'ink','demi','mm')
    surface(im,'ui_icon_button_normal',(1760,392,84,84),1.4);glyph(im,'close',1784,416,36)
    line(im,(74,494,1840,494))
    options=[('shelter','Shelter','2 x 2 tiles',60,20),('farm','Farm','2 x 2 tiles',50,0),
             ('watchtower','Watchtower','1 x 1 tile',80,20),('wall','Wood wall','1 x 1 tile',10,0)]
    for i,(key,label,foot,scrap,food) in enumerate(options):
        x=70+i*290;y=512
        surface(im,'ui_item_card_selected' if i==0 else 'ui_item_card_normal',(x,y,274,315),1.5)
        art(im,'ui_build_'+key,(x+12,y+5,250,175))
        text(im,(x+21,y+185),label,27,'ink','demi');text(im,(x+21,y+226),foot,20,'muted')
        art(im,'ui_item_scrap',(x+13,y+264,39,36));text(im,(x+59,y+268),str(scrap),23,'ink','demi')
        if food:art(im,'ui_item_food',(x+132,y+264,39,36));text(im,(x+177,y+268),str(food),23,'ink','demi')
    line(im,(1258,521,1258,816))
    text(im,(1300,525),'Shelter',34,'ink','bold')
    paragraph(im,(1300,581),'A safe place for four more survivors to call home.',480,25,leading=35)
    glyph(im,'clock',1302,678,28,'muted');text(im,(1346,677),'60 seconds',23,'muted')
    glyph(im,'home',1547,678,28,'muted');text(im,(1591,677),'+4 housing',23,'muted')
    button(im,(1290,737,516,87),'Place shelter',icon='plus',size=28)
    save(im,'02_build_menu_iphone.png')

def pause():
    im=background(1920,886,150)
    text(im,(60,47),'HIGHWAY HOLDOUT',27,'white','bold')
    text(im,(60,94),'Your town. Your pace.',24,'#B6CECA')
    surface(im,'ui_panel_dialog',(613,58,694,774))
    roundbox(im,(883,107,1037,147),19,'pale');text(im,(960,126),'DAY 12',19,'teal','demi','mm')
    text(im,(960,180),'Paused',52,'ink','bold','ma')
    text(im,(960,258),'Take a moment. The town can wait.',25,'muted','regular','ma')
    button(im,(669,328,582,100),'Resume',icon='play',size=30)
    button(im,(669,447,582,94),'Settings','secondary',icon='settings',size=28)
    button(im,(669,560,582,94),'Main menu','secondary',icon='home',size=28)
    line(im,(685,696,1235,696))
    glyph(im,'sound',750,735,34,'muted');text(im,(800,739),'Sound',24,'ink','medium')
    art(im,'ui_toggle_on',(1050,723,128,72))
    save(im,'03_pause_menu_iphone.png')

def states():
    im=Image.new('RGBA',(1800,1240),'#15363B')
    text(im,(48,36),'HIGHWAY HOLDOUT / UI COMPONENTS',38,'white','bold')
    text(im,(50,96),'Dimensional inventory art. Quiet surfaces. Clear interaction states.',24,'#B6CECA')
    labels=['normal','pressed','disabled']
    for i,label in enumerate(labels):text(im,(336+i*470,168),label.upper(),18,'#B6CECA','demi')
    for row,kind in enumerate(['primary','secondary','danger']):
        y=204+row*130;text(im,(50,y+29),kind.capitalize(),25,'white','demi')
        for i,state in enumerate(labels):button(im,(285+i*470,y,430,98),'Continue' if kind!='danger' else 'Demolish',kind,state,size=26)
    text(im,(50,618),'Item cards',26,'white','demi')
    for i,state in enumerate(['normal','selected','pressed','disabled','locked']):
        x=285+i*290;surface(im,'ui_item_card_'+state,(x,610,256,320))
        art(im,'ui_item_scrap',(x+22,625,212,218))
        if state=='locked':glyph(im,'lock',x+100,724,56,'muted')
        text(im,(x+22,856),'Salvaged scrap',21,'ink','demi');text(im,(x+22,892),'286',22,'teal','bold')
        text(im,(x+12,949),state.upper(),18,'#B6CECA','demi')
    text(im,(50,1040),'Navigation',26,'white','demi')
    for i,n in enumerate(['inventory','build','view_iso','view_topdown','settings','close','filter','search']):
        x=290+i*170;surface(im,'ui_icon_button_normal',(x,1030,96,96),1.5);glyph(im,n,x+26,1056,44)
    save(im,'04_component_states.png')

if __name__=='__main__':construction();pause();states()
