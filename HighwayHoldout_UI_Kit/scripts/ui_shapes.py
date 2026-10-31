"""Editable, stretchable UI surfaces. Text and quantities stay outside the art."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
COLORS={'ink':'#15363B','navy':'#10282D','muted':'#5F7775','paper':'#F5F0E5',
        'surface':'#E7DFCF','edge':'#C9BDA4','gold':'#DBAE63','coral':'#D17B56',
        'teal':'#2F706C','pale':'#DDEAE1','danger':'#A84D43','disabled':'#DDD9CF','white':'#FFFCF5'}
ASSETS=[]
def c(v):return COLORS.get(v,v)
def rect(x,y,w,h,r,fill,stroke='none',sw=1,extra=''):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{c(fill)}" stroke="{c(stroke)}" stroke-width="{sw}" {extra}/>'
def path(d,stroke='ink',sw=3,fill='none',extra=''):
    return f'<path d="{d}" fill="{c(fill)}" stroke="{c(stroke)}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'
def circle(x,y,r,fill,stroke='none',sw=1):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c(fill)}" stroke="{c(stroke)}" stroke-width="{sw}"/>'
def svg(w,h,body):return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'
def save(name,w,h,body,category='surface',caps=None,template=False,description=''):
    (ROOT/'source_svg'/f'{name}.svg').write_text(svg(w,h,body))
    ASSETS.append(dict(name=name,width=w,height=h,category=category,template=template,
        cap_insets_pt=caps,logical_width=w/2,logical_height=h/2,description=description))
def cap(t=20,l=24,b=24,r=24):return dict(top=t,left=l,bottom=b,right=r)

def surfaces():
    for name,fill,border in [('light','paper','edge'),('dark','navy','#426064'),('drawer','paper','gold'),('dialog','white','gold')]:
        s=rect(4,8,504,500,28,'#0B2025',extra='opacity=".22"')
        s+=rect(4,4,504,500,28,fill,border,2)
        s+=rect(10,10,492,488,23,'none','#688184' if name=='dark' else 'white',1)
        save('ui_panel_'+name,512,512,s,caps=cap(24,24,24,24),description=name.capitalize()+' menu panel, empty center')
    s=rect(3,7,378,101,25,'navy',extra='opacity=".18"')+rect(3,3,378,101,25,'navy','#426064',2)+path('M25 8H357','#688184',1)
    save('ui_resource_chip',384,112,s,caps=cap(18,22,20,22),description='Dark HUD resource container')
    for state in ['normal','selected','pressed','disabled','locked']:
        fill='white' if state in ['normal','selected'] else 'pale' if state=='pressed' else 'surface'
        stroke='teal' if state in ['selected','pressed'] else 'edge'
        s=rect(4,8,248,308,19,'ink',extra='opacity=".10"')+rect(4,4,248,308,19,fill,stroke,4 if state=='selected' else 2)
        if state=='selected':s+=path('M24 10H232','gold',3)
        if state=='disabled':s+=rect(12,12,232,292,13,'white',extra='opacity=".35"')
        save('ui_item_card_'+state,256,320,s,caps=cap(20,18,20,18),description='Inventory/build card: '+state)
    for kind in ['primary','secondary','danger']:
        for state in ['normal','pressed','disabled']:
            fill={'primary':'teal','secondary':'white','danger':'danger'}[kind]
            border='edge' if kind=='secondary' else 'ink'
            if state=='pressed':fill={'primary':'ink','secondary':'pale','danger':'#803F39'}[kind]
            if state=='disabled':fill='disabled';border='edge'
            s=rect(4,10,504,114,22,'ink',extra='opacity=".18"')+rect(4,4 if state!='pressed' else 8,504,112,22,fill,border,2)
            if state=='normal':s+=path('M28 10H484','white' if kind=='secondary' else '#79A099',1,extra='opacity=".45"')
            save(f'ui_button_{kind}_{state}',512,128,s,caps=cap(20,24,24,24),description=f'{kind.capitalize()} action / {state}')
    for state in ['normal','pressed','selected','disabled']:
        fill={'normal':'white','pressed':'pale','selected':'teal','disabled':'disabled'}[state]
        s=rect(4,8,120,116,24,'ink',extra='opacity=".14"')+rect(4,4,120,116,24,fill,'teal' if state=='selected' else 'edge',2)
        save('ui_icon_button_'+state,128,128,s,caps=cap(20,20,22,20),description='Square icon button / '+state)
    for state in ['normal','selected']:
        s=rect(3,3,378,104,20,'pale' if state=='selected' else 'paper','teal' if state=='selected' else 'edge',2)
        if state=='selected':s+=rect(24,99,336,5,2,'teal')
        save('ui_tab_'+state,384,112,s,caps=cap(18,22,18,22),description='Category tab / '+state)
    for name,fill in [('track','surface'),('teal','teal'),('amber','gold'),('danger','danger')]:
        s=rect(2,2,508,28,14,fill,'edge' if name=='track' else fill,1)
        save('ui_progress_'+name,512,32,s,caps=cap(7,7,7,7),description='Progress track' if name=='track' else 'Full progress fill; clip to value')
    for state in ['off','on']:
        s=rect(3,3,138,74,37,'teal' if state=='on' else 'surface','teal' if state=='on' else 'edge',2)
        s+=circle(105 if state=='on' else 39,40,29,'white','edge',1)
        save('ui_toggle_'+state,144,80,s,category='control',description='Toggle visual only: '+state)
    for state in ['off','on']:
        s=rect(4,4,56,56,12,'teal' if state=='on' else 'white','teal' if state=='on' else 'edge',2)
        if state=='on':s+=path('M17 32L28 43L48 21','white',5)
        save('ui_checkbox_'+state,64,64,s,category='control',description='Checkbox visual only: '+state)
    save('ui_badge_count',112,64,rect(3,3,106,58,29,'ink','gold',2),caps=cap(15,17,15,17),description='Blank quantity or notification badge')
    save('ui_badge_warning',80,80,circle(40,40,36,'danger','white',2),category='control',description='Blank warning badge; pair with alert glyph')
    save('ui_search_field',512,112,rect(3,3,506,106,20,'surface','edge',2),caps=cap(18,22,18,22),description='Search field background')
    save('ui_separator',512,8,rect(0,3,512,1,0,'edge'),caps=cap(0,0,0,0),description='Horizontal separator')
    save('ui_scroll_track',16,256,rect(4,4,8,248,4,'surface'),caps=cap(4,3,4,3),description='Scrollbar track')
    save('ui_scroll_thumb',16,96,rect(3,3,10,90,5,'muted'),caps=cap(4,3,4,3),description='Scrollbar thumb')

if __name__=='__main__':
    surfaces()
    from ui_glyphs import glyphs
    glyphs(save,path,rect,circle)
    (ROOT/'reference/vector_assets.json').write_text(json.dumps(ASSETS,indent=2)+'\n')
    (ROOT/'design_tokens.json').write_text(json.dumps({'colors':COLORS,'base_spacing_pt':4,
        'spacing_pt':[4,8,12,16,24,32],'touch_target_min_pt':44,
        'text_roles_pt':{'screen_title':28,'section_title':20,'body':16,'label':14,'caption':12},
        'typeface':'System font (SF); Avenir Next is used only in preview mockups',
        'resource_mappings':{'food':'ui_item_food','scrap':'ui_item_scrap','survivors':'ui_item_survivors'}},indent=2)+'\n')
    print(f'Created {len(ASSETS)} editable UI surface and glyph SVGs.')
