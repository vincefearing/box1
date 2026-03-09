"""Convert Pokemon cries from OGG to M4A and re-upload to Supabase.

Downloads OGGs from PokeAPI GitHub, converts to M4A with ffmpeg,
uploads to Supabase storage, and updates cry_url in the database.
"""

import os
import subprocess
import tempfile
import logging
import concurrent.futures
from pathlib import Path
from supabase import create_client
from dotenv import load_dotenv
import requests

logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)

CRIES_BASE_URL = "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest"
BUCKET_NAME = "pokemon-cries"
TEMP_DIR = Path(tempfile.mkdtemp(prefix="cries_"))


def get_pokemon_list() -> list:
    pokemon = []
    offset = 0
    while True:
        batch = (
            supabase.table("pokemon")
            .select("dex_number, name, cry_url")
            .order("dex_number")
            .range(offset, offset + 999)
            .execute()
        )
        pokemon.extend(batch.data)
        if len(batch.data) < 1000:
            break
        offset += 1000
    return pokemon


def download_and_convert(dex_number: int) -> tuple[int, Path | None]:
    """Download OGG from PokeAPI and convert to M4A. Returns (dex_number, m4a_path)."""
    ogg_path = TEMP_DIR / f"{dex_number}.ogg"
    m4a_path = TEMP_DIR / f"{dex_number}.m4a"

    try:
        response = requests.get(f"{CRIES_BASE_URL}/{dex_number}.ogg", timeout=15)
        response.raise_for_status()
        ogg_path.write_bytes(response.content)

        subprocess.run(
            ["ffmpeg", "-y", "-i", str(ogg_path), "-c:a", "aac", "-b:a", "128k", str(m4a_path)],
            capture_output=True,
            check=True,
        )
        ogg_path.unlink()
        return (dex_number, m4a_path)
    except Exception as e:
        logger.error(f"#{dex_number}: {e}")
        return (dex_number, None)


def main():
    pokemon_list = get_pokemon_list()

    # Skip already converted
    to_convert = [p for p in pokemon_list if p.get("cry_url") and ".m4a" not in p["cry_url"]]
    total = len(to_convert)
    print(f"Converting {total} cries (skipping {len(pokemon_list) - total} already done)")

    # Phase 1: Download and convert in parallel
    print("Phase 1: Downloading and converting...")
    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = {
            executor.submit(download_and_convert, p["dex_number"]): p
            for p in to_convert
        }
        done = 0
        for future in concurrent.futures.as_completed(futures):
            dex_number, m4a_path = future.result()
            results[dex_number] = m4a_path
            done += 1
            if done % 50 == 0:
                print(f"  Converted {done}/{total}")

    converted = {k: v for k, v in results.items() if v is not None}
    failed = total - len(converted)
    print(f"  Done: {len(converted)} converted, {failed} failed")

    # Phase 2: Upload to Supabase and update URLs
    print("Phase 2: Uploading to Supabase...")
    uploaded = 0
    errors = 0
    for dex_number, m4a_path in sorted(converted.items()):
        try:
            file_path = f"{dex_number}.m4a"
            m4a_data = m4a_path.read_bytes()

            try:
                supabase.storage.from_(BUCKET_NAME).remove([f"{dex_number}.ogg"])
            except Exception:
                pass

            supabase.storage.from_(BUCKET_NAME).upload(
                path=file_path,
                file=m4a_data,
                file_options={
                    "content-type": "audio/mp4",
                    "cache-control": "3600",
                    "upsert": "true",
                },
            )

            public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_path)
            supabase.table("pokemon").update({"cry_url": public_url}).eq(
                "dex_number", dex_number
            ).execute()

            uploaded += 1
            if uploaded % 50 == 0:
                print(f"  Uploaded {uploaded}/{len(converted)}")

            m4a_path.unlink(missing_ok=True)
        except Exception as e:
            logger.error(f"Upload #{dex_number}: {e}")
            errors += 1

    print(f"\nDone! {uploaded} uploaded, {errors} upload errors, {failed} conversion errors.")


if __name__ == "__main__":
    main()
