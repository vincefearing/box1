ALTER TABLE types ADD CONSTRAINT types_name_unique UNIQUE (name);
ALTER TABLE games ADD CONSTRAINT games_name_unique UNIQUE (name);