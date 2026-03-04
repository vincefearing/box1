import os
import requests
import logging
from supabase import create_client
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SECRET_KEY")
supabase = create_client(url, key)


def get_dex_numbers() -> list:
    response = (
        supabase.table("pokemon")
        .select("dex_number")
        .is_("description", "null")
        .execute()
    )

    dex_numbers = []
    for num_dict in response.data:
        dex_numbers.append(num_dict["dex_number"])

    return dex_numbers


def get_descriptions(dex_numbers: list) -> dict:
    base_url = "https://pokeapi.co/api/v2/pokemon-species/"
    descriptions = {}
    for num in dex_numbers:
        try:
            url = f"{base_url}{num}"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            logger.info(f"Request was successful. Status: {response.status_code}")

            dex_data = response.json()
            flavor_text_entries = dex_data["flavor_text_entries"]
            for text in flavor_text_entries:
                language_info = text["language"]
                if language_info["name"] == "en":
                    description = text["flavor_text"]
                    cleaned_text = description.replace("\n", " ").replace("\f", " ")
                    descriptions[num] = cleaned_text
                    break

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch {url}. Reason: {e}")

    return descriptions


def main():
    dex_numbers = get_dex_numbers()
    descriptions = get_descriptions(dex_numbers)
    for dex_num, desc in descriptions.items():
        supabase.table("pokemon").update({"description": desc}).eq("dex_number", dex_num).execute()
        logger.info(f"Pokemon: {dex_num} successfully added to db")


if __name__ == "__main__":
    main()