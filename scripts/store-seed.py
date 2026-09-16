#!/usr/bin/env python3
"""Build store-screenshot seed data from Last.fm.

Writes /tmp/seed-main.hex (the open grid, 25 slots) and /tmp/seed-saved.hex
(the saved grids list) in the app's stored JSON shape, hex-encoded for the
-FortyGridDict / -storedSavedGrids launch arguments. Also reuses the "2024"
grid already saved on the 15 Pro simulator.
"""
import json, plistlib, sys, urllib.parse, urllib.request, time

KEY = plistlib.load(open('/Users/austin/Developer/Topster/Topster/Secrets.plist', 'rb'))['API_KEY']
PRO_PLIST = sys.argv[1]

ALL_TIME = [
    ("Radiohead", "OK Computer"), ("Pink Floyd", "The Dark Side of the Moon"),
    ("Miles Davis", "Kind of Blue"), ("Fleetwood Mac", "Rumours"),
    ("The Beatles", "Abbey Road"), ("Kendrick Lamar", "good kid, m.A.A.d city"),
    ("Daft Punk", "Discovery"), ("Amy Winehouse", "Back to Black"),
    ("Nirvana", "Nevermind"), ("Frank Ocean", "Blonde"),
    ("Talking Heads", "Remain in Light"), ("Joy Division", "Unknown Pleasures"),
    ("David Bowie", "Hunky Dory"), ("Massive Attack", "Mezzanine"),
    ("Portishead", "Dummy"), ("My Bloody Valentine", "Loveless"),
    ("The Beach Boys", "Pet Sounds"), ("Stevie Wonder", "Songs in the Key of Life"),
    ("A Tribe Called Quest", "The Low End Theory"), ("Aphex Twin", "Selected Ambient Works 85-92"),
    ("Nas", "Illmatic"), ("Prince", "Purple Rain"),
    ("The Notorious B.I.G.", "Ready to Die"), ("Radiohead", "In Rainbows"),
    ("Björk", "Homogenic"),
]
HIP_HOP = [
    ("Madvillain", "Madvillainy"), ("Kendrick Lamar", "To Pimp a Butterfly"),
    ("OutKast", "Aquemini"), ("Wu-Tang Clan", "Enter the Wu-Tang (36 Chambers)"),
    ("MF DOOM", "MM..FOOD"), ("Kanye West", "My Beautiful Dark Twisted Fantasy"),
    ("J Dilla", "Donuts"), ("Lauryn Hill", "The Miseducation of Lauryn Hill"),
    ("A Tribe Called Quest", "Midnight Marauders"), ("Mobb Deep", "The Infamous"),
    ("Tyler, the Creator", "IGOR"), ("JPEGMAFIA", "LP!"),
    ("Earl Sweatshirt", "Some Rap Songs"), ("Danny Brown", "Atrocity Exhibition"),
    ("Freddie Gibbs", "Piñata"), ("Clipse", "Hell Hath No Fury"),
    ("Little Simz", "Sometimes I Might Be Introvert"), ("Denzel Curry", "Melt My Eyez See Your Future"),
    ("Vince Staples", "Summertime '06"), ("Nas", "Illmatic"),
]
JAZZ_SOUL = [
    ("John Coltrane", "A Love Supreme"), ("Marvin Gaye", "What's Going On"),
    ("Alice Coltrane", "Journey in Satchidananda"), ("D'Angelo", "Voodoo"),
    ("Charles Mingus", "Mingus Ah Um"), ("Erykah Badu", "Mama's Gun"),
    ("Herbie Hancock", "Head Hunters"), ("Nina Simone", "I Put a Spell on You"),
    ("Bill Evans Trio", "Sunday at the Village Vanguard"), ("Curtis Mayfield", "Superfly"),
    ("Thelonious Monk", "Monk's Dream"), ("Al Green", "Call Me"),
    ("Pharoah Sanders", "Karma"), ("Sade", "Love Deluxe"),
    ("Donny Hathaway", "Everything Is Everything"), ("Sun Ra", "Space Is the Place"),
    ("Solange", "A Seat at the Table"), ("Kamasi Washington", "The Epic"),
    ("Roberta Flack", "First Take"), ("Isaac Hayes", "Hot Buttered Soul"),
]
ELECTRONIC = [
    ("Boards of Canada", "Music Has the Right to Children"), ("Burial", "Untrue"),
    ("Aphex Twin", "Richard D. James Album"), ("Daft Punk", "Homework"),
    ("Kraftwerk", "Trans-Europe Express"), ("Four Tet", "Rounds"),
    ("Jamie xx", "In Colour"), ("Caribou", "Swim"),
    ("Autechre", "Tri Repetae"), ("The Avalanches", "Since I Left You"),
    ("Jon Hopkins", "Immunity"), ("Floating Points", "Crush"),
    ("Oneohtrix Point Never", "Replica"), ("Bicep", "Bicep"),
    ("Underworld", "Dubnobasswithmyheadman"), ("Röyksopp", "Melody A.M."),
    ("DJ Shadow", "Endtroducing....."), ("Justice", "Cross"),
    ("Massive Attack", "Mezzanine"), ("Fred again..", "Actual Life (April 14 - December 17 2020)"),
]


def lookup(artist, album):
    q = urllib.parse.urlencode({
        'method': 'album.getinfo', 'api_key': KEY, 'artist': artist,
        'album': album, 'format': 'json', 'autocorrect': 1})
    with urllib.request.urlopen('https://ws.audioscrobbler.com/2.0/?' + q, timeout=20) as r:
        d = json.load(r)
    a = d.get('album')
    if not a:
        return None
    images = a.get('image', [])
    big = next((i for i in images if i.get('size') == 'extralarge' and i.get('#text')), None)
    if not big:
        return None
    return {
        'name': a['name'], 'artist': a['artist'], 'url': a.get('url', ''),
        'image': [{'#text': i.get('#text', ''), 'size': i.get('size', '')} for i in images],
        'streamable': '0', 'mbid': a.get('mbid', '') or '',
    }


def grid(pairs, slots):
    out = {}
    slot = 1
    for artist, album in pairs:
        if slot > slots:
            break
        entry = lookup(artist, album)
        time.sleep(0.25)
        if entry is None:
            print('MISSING', artist, '-', album, file=sys.stderr)
            continue
        out[str(slot)] = entry
        slot += 1
    for k in range(slot, slots + 1):
        out[str(k)] = None
    print('grid', slots, 'filled', slot - 1, file=sys.stderr)
    return out


main = grid(ALL_TIME, 25)
saved = [
    {'grid': main, 'type': 'twentyFive', 'name': 'All time'},
    {'grid': grid(HIP_HOP, 20), 'type': 'twentyWide', 'name': 'Hip hop'},
    {'grid': grid(JAZZ_SOUL, 20), 'type': 'twentyWide', 'name': 'Jazz and soul'},
    {'grid': grid(ELECTRONIC, 20), 'type': 'twentyWide', 'name': 'Electronic'},
]
pro = plistlib.load(open(PRO_PLIST, 'rb'))
old = json.loads(pro['storedSavedGrids'])[4]
saved.append({'grid': old['grid'], 'type': 'fortyTwo', 'name': '2024'})

open('/tmp/seed-main.hex', 'w').write(json.dumps(main, ensure_ascii=False).encode('utf-8').hex())
open('/tmp/seed-saved.hex', 'w').write(json.dumps(saved, ensure_ascii=False).encode('utf-8').hex())
print('wrote /tmp/seed-main.hex and /tmp/seed-saved.hex')
