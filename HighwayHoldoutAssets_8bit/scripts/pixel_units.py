"""Hand-placed overhead units and east-facing weapon assemblies, at 32x32."""
from pixel_core import Canvas

def human(armed=False,gunner=False):
    c=Canvas()
    # Boots, shoulders and arms surround a head seen directly from above.
    c.rect((7,11,12,14),'ink');c.rect((7,18,12,21),'ink')
    c.rect((9,12,12,13),'asphalt');c.rect((9,19,12,20),'asphalt')
    c.poly([(11,10),(16,9),(20,11),(21,20),(17,23),(11,21)],'ink')
    c.rect((12,11,17,20),'orange' if armed else 'wood')
    c.rect((12,18,17,21),'dirt')
    c.rect((18,11,21,13),'ink');c.rect((18,20,22,22),'ink')
    c.rect((19,12,21,12),'orange' if armed else 'wood')
    c.rect((20,20,22,21),'wood')
    c.rect((22,12,23,14),'ink');c.rect((22,19,24,21),'ink')
    c.dot(22,13,'light');c.rect((23,19,23,20),'light')
    c.poly([(14,12),(18,12),(20,14),(20,18),(18,20),(14,20),(12,18),(12,14)],'ink')
    c.rect((14,13,18,18),'grass' if armed else 'dirt')
    c.rect((13,14,15,17),'skin' if armed else 'wood')
    c.rect((15,19,18,19),'dirt')
    c.rect((19,15,21,17),'wood' if armed else 'light')
    if armed:
        c.rect((19,14,26 if gunner else 25,16),'ink')
        c.rect((21,14,24,14),'metal');c.dot(19,15,'wood')
        if gunner:c.rect((26,15,28,15),'ink')
        c.dot(22,17,'metal');c.dot(20,11,'orange')
    else:
        c.rect((9,12,12,20),'ink');c.rect((10,13,11,19),'grass')
        c.rect((10,14,10,17),'skin')
    return c.im

def zombie(kind):
    c=Canvas()
    if kind=='runner':
        c.poly([(8,10),(10,9),(15,13),(14,16),(10,14)],'ink')
        c.rect((9,10,10,11),'asphalt');c.rect((12,12,13,14),'clothes')
        c.poly([(14,18),(16,20),(12,24),(8,23),(9,21)],'ink')
        c.rect((10,21,12,22),'clothes')
        c.poly([(13,12),(18,11),(21,16),(18,20),(13,20),(11,17)],'ink')
        c.rect((13,14,17,18),'clothes')
        c.poly([(18,12),(20,10),(24,10),(25,12),(23,14),(20,13)],'ink')
        c.rect((21,11,23,12),'skin')
        c.poly([(13,19),(11,20),(8,18),(8,16),(10,15)],'ink')
        c.rect((9,17,10,18),'skin')
        c.poly([(16,13),(20,13),(22,15),(22,18),(19,20),(16,19),(14,17)],'ink')
        c.rect((16,14,19,18),'skin');c.rect((20,15,21,17),'skin');c.dot(16,14,'grass')
    elif kind=='brute':
        c.rect((3,7,10,12),'ink');c.rect((3,21,10,26),'ink')
        c.rect((4,8,7,10),'asphalt');c.rect((4,22,7,24),'asphalt')
        c.poly([(9,6),(17,5),(22,8),(24,24),(18,27),(9,25),(7,20),(8,11)],'ink')
        c.rect((9,8,17,24),'clothes');c.rect((10,9,12,14),'grass')
        c.rect((15,7,21,25),'skin');c.rect((15,22,20,25),'grass')
        c.poly([(20,8),(24,6),(27,7),(28,5),(30,6),(29,11),(24,12),(20,11)],'ink')
        c.rect((22,8,26,10),'skin');c.rect((27,7,28,9),'skin')
        c.poly([(21,21),(25,23),(28,20),(30,21),(30,24),(26,26),(21,24)],'ink')
        c.rect((23,23,26,24),'skin');c.rect((27,22,28,23),'skin')
        c.poly([(14,10),(20,10),(23,13),(23,19),(20,22),(14,22),(11,19),(11,13)],'ink')
        c.rect((14,11,20,20),'skin');c.rect((12,14,13,18),'grass')
        c.rect((21,14,22,18),'grass');c.rect((14,11,17,12),'grass')
        c.rect((10,6,13,8),'clothes');c.rect((20,7,22,8),'clothes')
    else:
        c.rect((7,11,12,14),'ink');c.rect((7,19,12,22),'ink')
        c.rect((8,12,10,13),'asphalt');c.rect((8,20,10,21),'asphalt')
        c.poly([(11,10),(17,10),(21,13),(21,21),(16,23),(11,22),(10,18)],'ink')
        c.rect((12,11,17,21),'clothes');c.rect((12,13,13,16),'grass')
        c.poly([(19,11),(22,11),(24,12),(25,10),(27,11),(26,14),(22,15),(19,14)],'ink')
        c.rect((20,12,23,13),'skin');c.dot(25,12,'skin')
        c.poly([(19,20),(22,19),(25,20),(26,18),(28,19),(27,22),(24,23),(19,22)],'ink')
        c.rect((20,20,24,21),'skin');c.dot(26,20,'skin')
        c.poly([(14,12),(18,12),(21,14),(21,19),(18,21),(14,20),(12,18),(12,14)],'ink')
        c.rect((14,13,18,19),'skin');c.rect((19,15,20,18),'skin')
        c.rect((14,13,16,14),'grass');c.dot(13,16,'grass')
    return c.im

def mg():
    c=Canvas()
    c.line([(16,16),(10,7)],'ink',2);c.line([(16,16),(10,25)],'ink',2)
    c.line([(16,16),(24,23)],'ink',2)
    c.line([(16,16),(11,8)],'metal');c.line([(16,16),(11,24)],'metal')
    c.oval((12,12,20,20),'ink');c.oval((13,13,19,19),'asphalt')
    c.rect((10,13,21,18),'ink');c.rect((11,14,20,16),'metal')
    c.rect((8,14,11,17),'ink');c.rect((9,15,10,16),'wood')
    c.rect((21,14,28,16),'ink');c.rect((22,14,27,14),'metal')
    c.rect((15,18,19,22),'ink');c.rect((16,19,18,21),'grass')
    c.dot(16,19,'yellow');c.dot(18,19,'yellow')
    return c.im

CUSTOM={'unit_survivor':lambda:human(), 'unit_defender':lambda:human(True),
        'def_watchtower_gunner':lambda:human(True,True),'def_mg_nest_gun':mg,
        **{'zmb_'+k:lambda k=k:zombie(k) for k in ['walker','runner','brute']}}
