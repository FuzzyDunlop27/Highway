"""Consistent template glyphs for HUD, menus and the two world views."""
def glyphs(save,path,rect,circle):
    paths={
        'close':'M18 18L46 46M46 18L18 46',
        'back':'M38 14L20 32L38 50',
        'chevron_right':'M25 16L41 32L25 48',
        'check':'M14 32L27 45L51 19',
        'plus':'M32 15V49M15 32H49',
        'minus':'M15 32H49',
        'search':'M43 43L54 54',
        'filter':'M12 16H52L37 33V49L27 54V33Z',
        'sort':'M23 12V52M14 42L23 52L32 42M39 52V12M30 22L39 12L48 22',
        'grid':'M12 12H27V27H12ZM37 12H52V27H37ZM12 37H27V52H12ZM37 37H52V52H37Z',
        'list':'M23 16H52M23 32H52M23 48H52M12 16H13M12 32H13M12 48H13',
        'lock':'M21 28V21A11 11 0 0 1 43 21V28M16 28H48V53H16ZM32 38V44',
        'info':'M32 29V45M32 19V20',
        'alert':'M32 23V36M32 44V45M32 10L56 52H8Z',
        'settings':'M27 9H37L39 17L45 20L53 18L58 27L52 33L52 39L57 45L50 53L42 49L36 52L33 59L23 56L22 48L17 44L9 44L6 34L13 29L15 23L12 16L20 10Z',
        'pause':'M21 14V50M43 14V50',
        'play':'M22 13L50 32L22 51Z',
        'speed':'M12 16L33 32L12 48ZM34 16L55 32L34 48Z',
        'inventory':'M12 21H52V53H12ZM22 21V12H42V21M12 31H52M28 27H36V36H28Z',
        'build':'M17 48L38 22M28 14L36 7L54 22L46 31L37 24M13 44L22 51L15 58L6 51Z',
        'upgrade':'M32 9L53 30H41V54H23V30H11Z',
        'demolish':'M23 53V23Q23 10 37 10H49V20H38Q33 20 33 25V46L43 53L37 59Z',
        'home':'M9 29L32 9L55 29M16 25V53H48V25M27 53V36H37V53',
        'view_iso':'M8 36L32 23L56 36L32 50ZM21 29V15L33 8L45 15V29M21 15L33 22L45 15M33 22V36',
        'view_topdown':'M10 10H54V54H10ZM10 25H54M10 40H54M25 10V54M40 10V54',
        'move':'M32 7V57M7 32H57M24 15L32 7L40 15M24 49L32 57L40 49M15 24L7 32L15 40M49 24L57 32L49 40',
        'clock':'M32 18V33L43 39',
        'sound':'M12 25H23L37 13V51L23 39H12ZM45 24Q54 32 45 40M49 15Q65 32 49 49',
        'map':'M8 14L24 9L40 15L56 10V50L40 55L24 49L8 54ZM24 9V49M40 15V55',
        'star':'M32 9L39 24L55 26L43 38L46 55L32 47L18 55L21 38L9 26L25 24Z',
        'shield':'M32 9L52 17V32Q50 47 32 56Q14 47 12 32V17Z',
    }
    for name,d in paths.items():
        body=path(d,'#FFFFFF',4)
        if name=='search':body+=circle(28,28,18,'none','#FFFFFF',4)
        if name in ['info','clock']:body=circle(32,32,24,'none','#FFFFFF',4)+body
        if name=='settings':body+=circle(32,32,9,'none','#FFFFFF',4)
        save('ui_glyph_'+name,64,64,body,'glyph',template=True,description=name.replace('_',' ').capitalize()+' monochrome template glyph')
