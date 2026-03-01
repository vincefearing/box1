CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    dex_number INT NOT NULL REFERENCES pokemon(dex_number),
    game_id INT NOT NULL REFERENCES games(id),
    location_info JSONB
);