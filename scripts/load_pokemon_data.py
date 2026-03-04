import os
from supabase import create_client
from dotenv import load_dotenv
from constants import POKEMON_TYPES, GENERATION_BOUNDARIES, GENERATION_DEBUT_GAMES, GAMES, GAME_NAME_ALIASES, DLC_TO_PARENT_GAMES
from fetch_pokemon_data import fetch_html, parse_pokemon_data, get_master_pokemon_list

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)


def seed_types():
    types = []
    for name, color in POKEMON_TYPES.items():
        types.append({"name" : name, "color" : color})
    
    supabase.table("types").upsert(types, on_conflict="name").execute()


def seed_games():
    supabase.table("games").upsert(GAMES, on_conflict="name").execute()


def get_types():
    response = supabase.table("types").select("id, name").execute()
    types = {}
    
    for type_dict in response.data:
        types[type_dict["name"]] = type_dict["id"]
    
    return types


def get_games():
    response = supabase.table("games").select("id, name").execute()
    games = {}

    for game_dict in response.data:
        games[game_dict["name"]] = game_dict["id"]
    
    return games


def resolve_game_names(game_name):
    game_name = GAME_NAME_ALIASES.get(game_name, game_name)
    if game_name in DLC_TO_PARENT_GAMES:
        return DLC_TO_PARENT_GAMES[game_name]
    return [game_name]


def load_pokemon(data, type_lookup, game_lookup):

    pokemon = {
        "name": data["name"],
        "height": data["height"],
        "weight": data["weight"],
        "generation": data["generation"],
        "dex_number": int(data["dex_number"]),
        "description": data["description"],
        "evolution_chain": data["evolution_chain"]
    }
    
    supabase.table("pokemon").upsert(pokemon, on_conflict="dex_number").execute()

    pokemon_types = []
    for pokemon_type in data["pokemon_types"]:
        type_id = type_lookup[pokemon_type]
        pokemon_types.append({"dex_number": pokemon["dex_number"], "type_id": type_id})

    if pokemon_types:
        supabase.table("pokemon_types").upsert(pokemon_types, on_conflict="dex_number,type_id").execute()

    pokemon_sprites = []
    for name, forms in data["pokemon_sprites"].items():
        normal = forms["normal"]
        shiny = forms.get("shiny")
        
        pokemon_sprites.append({"dex_number": pokemon["dex_number"], "form_name": name, "normal_url": normal, "shiny_url": shiny})
    
    if pokemon_sprites:
        supabase.table("sprites").upsert(pokemon_sprites, on_conflict="dex_number,form_name").execute()

    locations = {}
    for game, location_info in data["location_data"].items():
        for resolved_game in resolve_game_names(game):
            if resolved_game in game_lookup:
                game_id = game_lookup[resolved_game]
                locations[game_id] = {"dex_number": pokemon["dex_number"], "game_id": game_id, "location_info": location_info}

    if locations:
        supabase.table("locations").upsert(list(locations.values()), on_conflict="dex_number,game_id").execute()

    regional_dex = {}
    for game, number in data["regional_dex_numbers"].items():
        for resolved_game in resolve_game_names(game):
            if resolved_game in game_lookup:
                game_id = game_lookup[resolved_game]
                regional_dex[game_id] = {"dex_number": pokemon["dex_number"], "game_id": game_id, "regional_number": number}

    if regional_dex:
        supabase.table("regional_dex_numbers").upsert(list(regional_dex.values()), on_conflict="dex_number,game_id").execute()


def main():
    import time

    seed_types()
    seed_games()
    type_lookup = get_types()
    game_lookup = get_games()

    base_url = "https://pokemondb.net"
    master_list = get_master_pokemon_list()
    total = len(master_list)

    for i, pokemon in enumerate(master_list, 1):
        print(f"[{i}/{total}] Loading {pokemon['name']}...")

        html = fetch_html(f"{base_url}{pokemon['url']}")
        data = parse_pokemon_data(html, pokemon["name"])

        if data:
            try:
                load_pokemon(data, type_lookup, game_lookup)
            except Exception as e:
                print(f"  ERROR loading {pokemon['name']}: {e}")

        time.sleep(1)

    print(f"Done! Loaded {total} Pokemon.")


if __name__ == "__main__":
    main()
