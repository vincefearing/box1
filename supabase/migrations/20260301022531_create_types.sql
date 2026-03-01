CREATE TABLE types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL
);

CREATE TABLE pokemon_types (
  id SERIAL PRIMARY KEY,
  dex_number INT NOT NULL REFERENCES pokemon(dex_number),
  type_id INT NOT NULL REFERENCES types(id)
);