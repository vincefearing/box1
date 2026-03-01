CREATE TABLE sprites (
    id SERIAL PRIMARY KEY,
    dex_number INT NOT NULL REFERENCES pokemon(dex_number),
    form_name TEXT NOT NULL,
    normal_url TEXT NOT NULL,
    shiny_url TEXT
);