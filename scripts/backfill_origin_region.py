import os
from supabase import create_client
from dotenv import load_dotenv
from constants import GENERATION_BOUNDARIES, GENERATION_REGIONS

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
sb = create_client(url, key)


def get_region_for_dex_number(dex_number):
    prev_end = 0
    for gen, end in GENERATION_BOUNDARIES:
        if dex_number <= end:
            return GENERATION_REGIONS[gen]
        prev_end = end
    return None


def backfill():
    first_page = sb.table("pokemon").select("dex_number").order("dex_number").range(0, 999).execute()
    second_page = sb.table("pokemon").select("dex_number").order("dex_number").range(1000, 1999).execute()
    pokemon_list = first_page.data + second_page.data

    updated = 0
    for p in pokemon_list:
        dex = p["dex_number"]
        region = get_region_for_dex_number(dex)
        if region:
            sb.table("pokemon").update({"origin_region": region}).eq(
                "dex_number", dex
            ).execute()
            updated += 1

    print(f"Updated {updated} Pokemon with origin_region")


if __name__ == "__main__":
    backfill()
