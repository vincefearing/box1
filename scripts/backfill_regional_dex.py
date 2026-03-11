import os
import time
from supabase import create_client
from dotenv import load_dotenv
from constants import GAME_NAME_ALIASES
from fetch_pokemon_data import fetch_html, get_regional_dex_numbers, get_master_pokemon_list
from bs4 import BeautifulSoup

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)

game_lookup = {g["name"]: g["id"] for g in supabase.table("games").select("id, name").execute().data}

base_url = "https://pokemondb.net"
master_list = get_master_pokemon_list()
total = len(master_list)

for i, pokemon in enumerate(master_list, 1):
    print(f"[{i}/{total}] {pokemon['name']}...", end=" ")

    html = fetch_html(f"{base_url}{pokemon['url']}")
    if not html:
        print("SKIP (no html)")
        continue

    soup = BeautifulSoup(html, "html.parser")
    dex_number_header = soup.find("th", string="National №")
    dex_number = int(dex_number_header.find_next_sibling("td").get_text(strip=True)) if dex_number_header else None
    if not dex_number:
        print("SKIP (no dex #)")
        continue

    raw = get_regional_dex_numbers(soup)

    regional_dex = {}
    for game, number in raw.items():
        game = GAME_NAME_ALIASES.get(game, game)
        if game in game_lookup:
            game_id = game_lookup[game]
            regional_dex[game_id] = {"dex_number": dex_number, "game_id": game_id, "regional_number": number}

    if regional_dex:
        supabase.table("regional_dex_numbers").upsert(list(regional_dex.values()), on_conflict="dex_number,game_id").execute()

    print(f"{len(regional_dex)} entries")
    time.sleep(0.5)

print(f"\nDone! Processed {total} Pokemon.")
