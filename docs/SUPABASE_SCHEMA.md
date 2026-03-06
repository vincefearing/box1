# Supabase Schema Reference

## pokemon

| Column | Type |
|---|---|
| dex_number | int (PK) |
| name | text |
| height | real |
| weight | real |
| generation | int |
| description | text (nullable) |
| cry_url | text |
| evolution_chain | jsonb |
| origin_region | text |

## types

| Column | Type |
|---|---|
| id | int (PK) |
| name | text |
| color | text |

## pokemon_types

| Column | Type |
|---|---|
| id | int (PK) |
| dex_number | int (FK → pokemon) |
| type_id | int (FK → types) |

## sprites

| Column | Type |
|---|---|
| id | int (PK) |
| dex_number | int (FK → pokemon) |
| form_name | text |
| normal_url | text |
| shiny_url | text (nullable) |

## games

| Column | Type |
|---|---|
| id | int (PK) |
| name | text |
| generation | int |
| region | text |

## locations

| Column | Type |
|---|---|
| id | int (PK) |
| dex_number | int (FK → pokemon) |
| game_id | int (FK → games) |
| location_info | text |

## regional_dex_numbers

| Column | Type |
|---|---|
| id | int (PK) |
| dex_number | int (FK → pokemon) |
| game_id | int (FK → games) |
| regional_number | int |
