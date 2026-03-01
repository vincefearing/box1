CREATE TABLE pokemon (
  dex_number INT PRIMARY KEY,
  name TEXT NOT NULL,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  generation INT NOT NULL,
  description TEXT NOT NULL,
  cry_url TEXT,
  evolution_chain JSONB
);