/// Initial database schema (version 1).
///
/// Applied in `AppDatabase`'s `onCreate` callback. Statements are executed
/// in order inside a single transaction by sqflite.
library;

const List<String> migrationV1 = [
  '''
  CREATE TABLE recipes (
      id                 TEXT PRIMARY KEY,
      title              TEXT NOT NULL,
      description        TEXT,
      servings           INTEGER,
      prep_time_minutes  INTEGER,
      cook_time_minutes  INTEGER,
      is_favorite        INTEGER NOT NULL DEFAULT 0,
      created_at         TEXT NOT NULL,
      updated_at         TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE ingredients (
      id          TEXT PRIMARY KEY,
      recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      name        TEXT NOT NULL,
      quantity    REAL,
      unit        TEXT,
      sort_order  INTEGER NOT NULL DEFAULT 0,
      created_at  TEXT NOT NULL,
      updated_at  TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE recipe_steps (
      id                 TEXT PRIMARY KEY,
      recipe_id          TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      step_number        INTEGER NOT NULL,
      instruction        TEXT NOT NULL,
      duration_minutes   INTEGER,
      created_at         TEXT NOT NULL,
      updated_at         TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE recipe_images (
      id          TEXT PRIMARY KEY,
      recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      file_path   TEXT NOT NULL,
      is_primary  INTEGER NOT NULL DEFAULT 0,
      sort_order  INTEGER NOT NULL DEFAULT 0,
      created_at  TEXT NOT NULL,
      updated_at  TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE tags (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL UNIQUE,
      created_at  TEXT NOT NULL,
      updated_at  TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE recipe_tags (
      recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      tag_id      TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
      created_at  TEXT NOT NULL,
      PRIMARY KEY (recipe_id, tag_id)
  )
  ''',
  '''
  CREATE TABLE recipe_versions (
      id               TEXT PRIMARY KEY,
      recipe_id        TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      version_number   INTEGER NOT NULL,
      note             TEXT,
      snapshot_json    TEXT NOT NULL,
      created_at       TEXT NOT NULL,
      UNIQUE (recipe_id, version_number)
  )
  ''',
  '''
  CREATE TABLE shopping_list_items (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      quantity    REAL,
      unit        TEXT,
      category    TEXT,
      is_checked  INTEGER NOT NULL DEFAULT 0,
      recipe_id   TEXT REFERENCES recipes(id) ON DELETE SET NULL,
      created_at  TEXT NOT NULL,
      updated_at  TEXT NOT NULL
  )
  ''',

  // Indexes
  'CREATE INDEX idx_recipes_title ON recipes(title)',
  'CREATE INDEX idx_recipes_is_favorite ON recipes(is_favorite)',
  'CREATE INDEX idx_ingredients_recipe_id ON ingredients(recipe_id)',
  'CREATE INDEX idx_recipe_steps_recipe_id ON recipe_steps(recipe_id)',
  'CREATE INDEX idx_recipe_images_recipe_id ON recipe_images(recipe_id)',
  'CREATE INDEX idx_recipe_tags_tag_id ON recipe_tags(tag_id)',
  'CREATE INDEX idx_recipe_versions_recipe_id ON recipe_versions(recipe_id)',
  'CREATE INDEX idx_shopping_list_items_recipe_id ON shopping_list_items(recipe_id)',
  'CREATE INDEX idx_shopping_list_items_is_checked ON shopping_list_items(is_checked)',
  'CREATE INDEX idx_shopping_list_items_category ON shopping_list_items(category)',
];
