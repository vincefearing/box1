import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)

# Map each Pokemon missing a "default" sprite to their canonical base form
BASE_FORMS = {
    29: "female",          # Nidoran♀
    32: "male",            # Nidoran♂
    201: "a",              # Unown
    386: "normal",         # Deoxys
    412: "plant",          # Burmy
    413: "plant",          # Wormadam
    421: "overcast",       # Cherrim
    422: "west",           # Shellos
    423: "west",           # Gastrodon
    487: "altered",        # Giratina
    492: "land",           # Shaymin
    493: "normal",         # Arceus
    550: "red-striped",    # Basculin
    555: "standard",       # Darmanitan
    585: "spring",         # Deerling
    586: "spring",         # Sawsbuck
    641: "incarnate",      # Tornadus
    642: "incarnate",      # Thundurus
    645: "incarnate",      # Landorus
    647: "ordinary",       # Keldeo
    648: "aria",           # Meloetta
    666: "meadow",         # Vivillon
    669: "red",            # Flabébé
    670: "red",            # Floette
    671: "red",            # Florges
    676: "natural",        # Furfrou
    678: "male",           # Meowstic
    681: "shield",         # Aegislash
    710: "average",        # Pumpkaboo
    711: "average",        # Gourgeist
    718: "50",             # Zygarde
    720: "confined",       # Hoopa
    741: "baile",          # Oricorio
    745: "midday",         # Lycanroc
    746: "solo",           # Wishiwashi
    773: "normal",         # Silvally
    774: None,             # Minior - no sprites at all
    849: "amped",          # Toxtricity
    869: "vanilla-cream-strawberry",  # Alcremie
    875: "ice",            # Eiscue
    876: "male",           # Indeedee
    877: "full-belly",     # Morpeko
    888: "hero",           # Zacian
    889: "hero",           # Zamazenta
    892: "single-strike",  # Urshifu
    902: "male",           # Basculegion
    905: "incarnate",      # Enamorus
    916: "male",           # Oinkologne
    925: "family4",        # Maushold
    931: "green",          # Squawkabilly
    964: "zero",           # Palafin
    978: "curly",          # Tatsugiri
    982: "two-segment",    # Dudunsparce
    999: "chest",          # Gimmighoul
    1017: "teal",          # Ogerpon
    1024: "normal",        # Terapagos
}

updated = 0
skipped = 0

for dex_number, base_form in BASE_FORMS.items():
    if base_form is None:
        print(f"  #{dex_number}: no sprites available, skipping")
        skipped += 1
        continue

    # Get the base form sprite data
    result = supabase.table("sprites").select("*").eq("dex_number", dex_number).eq("form_name", base_form).execute()

    if not result.data:
        print(f"  #{dex_number}: form '{base_form}' not found, skipping")
        skipped += 1
        continue

    sprite = result.data[0]

    # Insert a "default" copy
    supabase.table("sprites").upsert({
        "dex_number": dex_number,
        "form_name": "default",
        "normal_url": sprite["normal_url"],
        "shiny_url": sprite.get("shiny_url"),
    }, on_conflict="dex_number,form_name").execute()

    print(f"  #{dex_number}: {base_form} → default")
    updated += 1

print(f"\nAdded {updated} default sprites, skipped {skipped}")
