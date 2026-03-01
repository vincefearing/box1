CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    generation INT NOT NULL,
    region TEXT NOT NULL
);