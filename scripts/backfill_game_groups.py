import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)

GAME_GROUPS = {
    "Red": "Red & Blue",
    "Blue": "Red & Blue",
    "Yellow": "Yellow",
    "Gold": "Gold & Silver",
    "Silver": "Gold & Silver",
    "Crystal": "Crystal",
    "Ruby": "Ruby & Sapphire",
    "Sapphire": "Ruby & Sapphire",
    "Emerald": "Emerald",
    "FireRed": "FireRed & LeafGreen",
    "LeafGreen": "FireRed & LeafGreen",
    "Diamond": "Diamond & Pearl",
    "Pearl": "Diamond & Pearl",
    "Platinum": "Platinum",
    "HeartGold": "HeartGold & SoulSilver",
    "SoulSilver": "HeartGold & SoulSilver",
    "Black": "Black & White",
    "White": "Black & White",
    "Black 2": "Black 2 & White 2",
    "White 2": "Black 2 & White 2",
    "X": "X & Y",
    "Y": "X & Y",
    "Omega Ruby": "Omega Ruby & Alpha Sapphire",
    "Alpha Sapphire": "Omega Ruby & Alpha Sapphire",
    "Sun": "Sun & Moon",
    "Moon": "Sun & Moon",
    "Ultra Sun": "Ultra Sun & Ultra Moon",
    "Ultra Moon": "Ultra Sun & Ultra Moon",
    "Let's Go Pikachu": "Let's Go Pikachu & Eevee",
    "Let's Go Eevee": "Let's Go Pikachu & Eevee",
    "Sword": "Sword & Shield",
    "Shield": "Sword & Shield",
    "Brilliant Diamond": "Brilliant Diamond & Shining Pearl",
    "Shining Pearl": "Brilliant Diamond & Shining Pearl",
    "Legends: Arceus": "Legends: Arceus",
    "Scarlet": "Scarlet & Violet",
    "Violet": "Scarlet & Violet",
    "Legends: Z-A": "Legends: Z-A",
}

games = supabase.table("games").select("id, name").execute().data

updated = 0
for game in games:
    group = GAME_GROUPS.get(game["name"])
    if group:
        supabase.table("games").update({"game_group": group}).eq("id", game["id"]).execute()
        print(f"  {game['name']} → {group}")
        updated += 1
    else:
        print(f"  WARNING: No group mapping for '{game['name']}'")

print(f"\nUpdated {updated}/{len(games)} games")
