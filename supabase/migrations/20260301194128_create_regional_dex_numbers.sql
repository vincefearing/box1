CREATE TABLE regional_dex_numbers (
    id SERIAL PRIMARY KEY,
    dex_number INT NOT NULL REFERENCES pokemon(dex_number),
    game_id INT NOT NULL REFERENCES games(id),
    regional_number INT NOT NULL
);