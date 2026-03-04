import os
import time
import requests
import logging
from supabase import create_client
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)

CRIES_BASE_URL = "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest"
BUCKET_NAME = "pokemon-cries"


def create_bucket():
    try:
        supabase.storage.create_bucket(BUCKET_NAME, options={"public": True})
        logger.info(f"Created bucket: {BUCKET_NAME}")
    except Exception as e:
        logger.info(f"Bucket may already exist: {e}")


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


def download_cry(dex_number: int) -> bytes:
    url = f"{CRIES_BASE_URL}/{dex_number}.ogg"
    response = requests.get(url, timeout=15)
    response.raise_for_status()
    return response.content


def upload_cry(dex_number: int, cry_data: bytes) -> str:
    file_path = f"{dex_number}.ogg"
    supabase.storage.from_(BUCKET_NAME).upload(
        path=file_path,
        file=cry_data,
        file_options={
            "content-type": "audio/ogg",
            "cache-control": "3600",
            "upsert": "true",
        },
    )
    public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_path)
    return public_url


def main():
    create_bucket()
    pokemon_list = get_pokemon_list()
    total = len(pokemon_list)

    for i, pokemon in enumerate(pokemon_list, 1):
        dex_number = pokemon["dex_number"]
        name = pokemon["name"]
        print(f"[{i}/{total}] {name} (#{dex_number})")

        try:
            cry_data = download_cry(dex_number)
            public_url = upload_cry(dex_number, cry_data)
            supabase.table("pokemon").update({"cry_url": public_url}).eq("dex_number", dex_number).execute()
        except Exception as e:
            logger.error(f"  ERROR: {name} - {e}")

        time.sleep(1)

    print(f"Done! Processed {total} Pokemon.")


if __name__ == "__main__":
    main()
