import os
import time
import requests
import logging
from bs4 import BeautifulSoup
from supabase import create_client
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)

# Bulbapedia game names that don't match our DB names
BULBA_GAME_ALIASES = {
    "Let's Go, Pikachu!": "Let's Go Pikachu",
    "Let's Go, Eevee!": "Let's Go Eevee",
}

# Bulbapedia DLC/sub-region names mapped to parent games
BULBA_DLC_TO_PARENT = {
    "Expansion Pass": ["Sword", "Shield"],
    "The Isle of Armor": ["Sword", "Shield"],
    "The Crown Tundra": ["Sword", "Shield"],
    "The Hidden Treasure of Area Zero": ["Scarlet", "Violet"],
    "The Teal Mask": ["Scarlet", "Violet"],
    "The Indigo Disk": ["Scarlet", "Violet"],
    "Mega Dimension": ["Legends: Z-A"],
}

# Pal Park is a transfer location in all 5 Gen 4 games — only used as fallback
PAL_PARK_GAMES = ["Diamond", "Pearl", "Platinum", "HeartGold", "SoulSilver"]

# Names to skip entirely (not in our DB)
SKIP_GAMES = {"Blue (Japan)", "Colosseum", "XD"}


def get_game_lookup() -> dict:
    response = supabase.table("games").select("id, name").execute()
    return {g["name"]: g["id"] for g in response.data}


def get_pokemon_list() -> list:
    pokemon = []
    offset = 0
    while True:
        batch = supabase.table("pokemon").select("dex_number, name").order("dex_number").range(offset, offset + 999).execute()
        pokemon.extend(batch.data)
        if len(batch.data) < 1000:
            break
        offset += 1000
    return pokemon


def fetch_bulbapedia(pokemon_name: str) -> str:
    formatted = pokemon_name.replace(" ", "_")
    url = f"https://bulbapedia.bulbagarden.net/wiki/{formatted}_(Pok%C3%A9mon)"
    response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15)
    response.raise_for_status()
    return response.text


def parse_locations(html: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")
    header = soup.find("span", id="Game_locations")
    if not header:
        return {}

    parent = header.parent
    table = parent.find_next_sibling("table")
    if not table:
        return {}

    results = {}
    loc_cells = table.find_all("td", class_="roundy", style=lambda s: s and "padding-left" in s)

    for cell in loc_cells:
        loc_text = cell.get_text(separator=" ", strip=True)
        outer_table = cell.find_parent("table", style=lambda s: s and "border-radius: 12px" in s)
        if outer_table:
            game_row = outer_table.find_parent("tr")
            if game_row:
                ths = game_row.find_all("th", recursive=False)
                games = [th.get_text(strip=True) for th in ths if "Generation" not in th.get_text()]
                for game in games:
                    if game:
                        results[game] = loc_text

    return results


def resolve_game_name(bulba_name: str) -> list:
    if bulba_name in SKIP_GAMES:
        return []
    bulba_name = BULBA_GAME_ALIASES.get(bulba_name, bulba_name)
    if bulba_name in BULBA_DLC_TO_PARENT:
        return BULBA_DLC_TO_PARENT[bulba_name]
    return [bulba_name]


def main():
    game_lookup = get_game_lookup()
    pokemon_list = get_pokemon_list()
    total = len(pokemon_list)

    for i, pokemon in enumerate(pokemon_list, 1):
        dex_number = pokemon["dex_number"]
        name = pokemon["name"]
        print(f"[{i}/{total}] {name} (#{dex_number})")

        try:
            html = fetch_bulbapedia(name)
            raw_locations = parse_locations(html)

            locations = {}
            pal_park_text = None

            for game, loc_text in raw_locations.items():
                if game == "Pal Park":
                    pal_park_text = loc_text
                    continue
                is_dlc = game in BULBA_DLC_TO_PARENT
                for resolved in resolve_game_name(game):
                    if resolved in game_lookup:
                        game_id = game_lookup[resolved]
                        if is_dlc and game_id in locations:
                            existing = locations[game_id]["location_info"]
                            locations[game_id]["location_info"] = f"{existing}; {loc_text}"
                        else:
                            locations[game_id] = {
                                "dex_number": dex_number,
                                "game_id": game_id,
                                "location_info": loc_text,
                            }

            if pal_park_text:
                for game in PAL_PARK_GAMES:
                    game_id = game_lookup[game]
                    if game_id not in locations:
                        locations[game_id] = {
                            "dex_number": dex_number,
                            "game_id": game_id,
                            "location_info": pal_park_text,
                        }

            if locations:
                supabase.table("locations").upsert(
                    list(locations.values()), on_conflict="dex_number,game_id"
                ).execute()

        except Exception as e:
            logger.error(f"  ERROR: {name} - {e}")

        time.sleep(1)

    print(f"Done! Processed {total} Pokemon.")


if __name__ == "__main__":
    main()
