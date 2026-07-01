# Recipe Book — arhitektura (prijedlog)

Osobna offline-first Flutter aplikacija za recepte. Bez login-a, bez backend-a
(MVP), lokalna SQLite baza + lokalno spremljene slike na disku.

## 1. Pristup arhitekturi

Za projekt ove veličine (jedan korisnik, bez backend-a, bez timova koji rade
paralelno) **puna Clean Architecture (domain/data/presentation po feature-u s
use-case klasama za svaku akciju) je overkill** — donosi puno boilerplate-a
(UseCase klase, mapperi, repository interface + impl parovi) bez realne
koristi jer nema alternativnih data source-ova ni potrebe za testiranjem
enterprise-style.

Prijedlog: **jednostavna layered arhitektura po feature-ima**, s jasnom
separacijom (UI → repository → data source), ali bez nepotrebnih apstrakcija:

```
UI (Widgets, Screens)
   ↓ poziva
Providers / Notifiers (state management)
   ↓ pozivaju
Repositories (jedan po entitetu, npr. RecipeRepository)
   ↓ koriste
Data sources (SQLite preko sqflite, file storage za slike)
```

- Repository sloj i dalje postoji kao apstrakcija (lakše je kasnije zamijeniti
  SQLite nečim drugim ili dodati sync/backend u v2), ali *nema* zasebnog
  domain sloja s use-case objektima za svaku operaciju — repository metode
  (`getAll()`, `getById()`, `insert()`, `update()`, `delete()`) su dovoljne.
- State management: **Riverpod** (ili Provider ako želiš nešto minimalnije) —
  preporučujem Riverpod (`flutter_riverpod` + `riverpod_generator`) jer dobro
  radi s async state-om (liste recepata, search, favoriti) i lako se testira.
- Navigacija: **go_router** (deklarativno, lako za detail/edit rute s ID-em).

## 2. Struktura foldera

```
lib/
├── main.dart
├── app.dart                       # MaterialApp / GoRouter setup
│
├── core/
│   ├── database/
│   │   ├── app_database.dart      # otvaranje baze, migracije
│   │   └── migrations/
│   │       ├── migration_v1.dart
│   │       └── ...
│   ├── storage/
│   │   └── image_storage_service.dart   # spremanje/brisanje slika na disk
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── id_generator.dart      # uuid helper
│
├── models/
│   ├── recipe.dart
│   ├── ingredient.dart
│   ├── recipe_step.dart
│   ├── recipe_image.dart
│   ├── recipe_tag.dart
│   ├── recipe_version.dart
│   └── shopping_list_item.dart
│
├── repositories/
│   ├── recipe_repository.dart
│   ├── tag_repository.dart
│   ├── shopping_list_repository.dart
│   └── recipe_version_repository.dart
│
├── providers/                     # riverpod provideri (state)
│   ├── recipe_list_provider.dart
│   ├── recipe_detail_provider.dart
│   ├── search_provider.dart
│   ├── favorites_provider.dart
│   └── shopping_list_provider.dart
│
└── features/
    ├── recipe_list/
    │   ├── recipe_list_screen.dart
    │   └── widgets/
    │       ├── recipe_card.dart
    │       └── recipe_search_bar.dart
    ├── recipe_detail/
    │   ├── recipe_detail_screen.dart
    │   └── widgets/
    │       ├── ingredient_list.dart
    │       ├── step_list.dart
    │       └── image_gallery.dart
    ├── recipe_edit/
    │   ├── recipe_edit_screen.dart
    │   └── widgets/
    │       ├── ingredient_form.dart
    │       ├── step_form.dart
    │       ├── image_picker_field.dart
    │       └── tag_selector.dart
    └── shopping_list/
        ├── shopping_list_screen.dart
        └── widgets/
            └── shopping_list_item_tile.dart

test/
├── repositories/
└── models/
```

Napomena: `features/` sadrži samo UI (screens + widgets specifični za taj
ekran); dijeljena logika (repozitoriji, provideri, modeli) živi izvan
`features/` da je lako reuse-ati (npr. `recipe_detail` i `recipe_edit` oba
trebaju `Recipe` model i `RecipeRepository`).

## 3. Data modeli (Dart)

Svi modeli su immutable (`final` polja), s `fromMap`/`toMap` za SQLite i
`copyWith` za edit flow. ID-evi su `String` (UUID v4) — lakše za offline rad
i buduću sinkronizaciju nego auto-increment int.

```dart
class Recipe {
  final String id;
  final String title;
  final String? description;
  final int? servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Ingredient {
  final String id;
  final String recipeId;
  final String name;
  final double? quantity;
  final String? unit;          // "g", "ml", "kom", ...
  final int sortOrder;
}

class RecipeStep {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String instruction;
  final int? durationMinutes;  // opcionalno, za timer u budućnosti
}

class RecipeImage {
  final String id;
  final String recipeId;
  final String filePath;       // relativna putanja u app documents dir
  final bool isCover;
  final int sortOrder;
}

class RecipeTag {
  final String id;
  final String name;
}

// many-to-many veza recept <-> tag ide preko join tablice (recipe_tags),
// nije potreban zaseban model — repository vraća List<RecipeTag> uz Recipe

class RecipeVersion {
  final String id;
  final String recipeId;
  final int versionNumber;
  final String snapshotJson; // serijalizirani cijeli recept (title, ingredients, steps...) u tom trenutku
  final DateTime createdAt;
}

class ShoppingListItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final bool isChecked;
  final String? recipeId;      // nullable — item može biti ručno dodan, ne mora doći iz recepta
}
```

`RecipeVersion` čuva snapshot cijelog recepta kao JSON (title + ingredients +
steps) u trenutku spremanja — jednostavnije od potpunog event-sourcinga i
dovoljno za "povijest izmjena / rollback" funkcionalnost.

## 4. SQLite shema

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE recipes (
    id                 TEXT PRIMARY KEY,
    title              TEXT NOT NULL,
    description        TEXT,
    servings           INTEGER,
    prep_time_minutes  INTEGER,
    cook_time_minutes  INTEGER,
    is_favorite        INTEGER NOT NULL DEFAULT 0,   -- 0/1
    created_at         TEXT NOT NULL,                -- ISO8601
    updated_at         TEXT NOT NULL
);

CREATE TABLE ingredients (
    id          TEXT PRIMARY KEY,
    recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    quantity    REAL,
    unit        TEXT,
    sort_order  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE recipe_steps (
    id                  TEXT PRIMARY KEY,
    recipe_id           TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    step_number         INTEGER NOT NULL,
    instruction         TEXT NOT NULL,
    duration_minutes    INTEGER
);

CREATE TABLE recipe_images (
    id          TEXT PRIMARY KEY,
    recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    file_path   TEXT NOT NULL,
    is_cover    INTEGER NOT NULL DEFAULT 0,
    sort_order  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE tags (
    id      TEXT PRIMARY KEY,
    name    TEXT NOT NULL UNIQUE
);

CREATE TABLE recipe_tags (
    recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    tag_id      TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (recipe_id, tag_id)
);

CREATE TABLE recipe_versions (
    id               TEXT PRIMARY KEY,
    recipe_id        TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    version_number   INTEGER NOT NULL,
    snapshot_json    TEXT NOT NULL,
    created_at       TEXT NOT NULL
);

CREATE TABLE shopping_list_items (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    quantity    REAL,
    unit        TEXT,
    is_checked  INTEGER NOT NULL DEFAULT 0,
    recipe_id   TEXT REFERENCES recipes(id) ON DELETE SET NULL
);

-- indeksi za tipične upite
CREATE INDEX idx_ingredients_recipe_id      ON ingredients(recipe_id);
CREATE INDEX idx_recipe_steps_recipe_id     ON recipe_steps(recipe_id);
CREATE INDEX idx_recipe_images_recipe_id    ON recipe_images(recipe_id);
CREATE INDEX idx_recipe_versions_recipe_id  ON recipe_versions(recipe_id);
CREATE INDEX idx_shopping_list_recipe_id    ON shopping_list_items(recipe_id);
CREATE INDEX idx_recipes_title              ON recipes(title);
CREATE INDEX idx_recipes_is_favorite        ON recipes(is_favorite);
```

Napomene:
- `ON DELETE CASCADE` na svim child tablicama vezanim uz `recipes` — brisanje
  recepta briše sastojke, korake, slike, tagove-veze i verzije automatski.
  Fizičke slike na disku i dalje treba ručno obrisati (repository/service
  sloj, ne baza) prilikom brisanja recepta.
- Pretraga (search) po naslovu/opisu: za MVP dovoljan je `LIKE '%query%'` na
  `title`/`description` uz `idx_recipes_title`. Ako search postane spor ili
  zatreba pretraga i po sastojcima, kasnije se doda SQLite FTS5 virtualna
  tablica (`recipes_fts`) — ne treba je raditi odmah.
- Baza se inicijalizira/migrira preko `sqflite`-ovog `onCreate`/`onUpgrade`
  callbacka u `core/database/app_database.dart`; svaka promjena sheme dobiva
  vlastiti `migration_vN.dart` fajl s SQL-om za upgrade.

## 5. Slike na disku

- Slike se kopiraju iz image pickera u `<app documents dir>/recipe_images/<recipeId>/<imageId>.jpg`.
- U bazi (`recipe_images.file_path`) sprema se **relativna** putanja
  (`recipe_images/<recipeId>/<imageId>.jpg`), ne apsolutna — apsolutna
  putanja aplikacije se može promijeniti između instalacija/OS verzija.
- `ImageStorageService` (u `core/storage/`) je zadužen za copy/delete
  fizičkih fajlova; repository poziva taj servis pa tek onda upisuje red u
  bazu (i obrnuto kod brisanja).

## 6. Prijedlog paketa (pubspec)

- `sqflite` + `path` — SQLite
- `path_provider` — app documents dir za slike
- `image_picker` — biranje/fotografiranje slika
- `flutter_riverpod` — state management
- `go_router` — navigacija
- `uuid` — generiranje ID-eva
- `intl` — formatiranje datuma (za `updated_at`, prikaz u UI-u)

## 7. Redoslijed implementacije (prijedlog)

1. `core/database` (schema + migracije) i modeli s `fromMap`/`toMap`
2. `RecipeRepository` (CRUD za recipe + ingredients + steps u transakciji)
3. Recipe list screen + detail screen (read-only prvo)
4. Recipe add/edit screen (forme za sastojke i korake)
5. Slike (`ImageStorageService` + `RecipeImage` CRUD + galerija)
6. Tagovi + tag selector
7. Favoriti (toggle na listi/detaljima)
8. Pretraga (search bar nad listom)
9. Shopping list (generiranje iz sastojaka recepta + ručni unos)
10. Recipe versions (snapshot pri svakom spremanju, ekran povijesti — može i van MVP-a)

---

Ovo je prijedlog za review prije pisanja koda. Javi ako želiš promijeniti
state management (npr. Provider/Bloc umjesto Riverpod), izbaciti/dodati neki
entitet, ili promijeniti neku odluku u shemi (npr. int ID-evi umjesto UUID-a)
pa krećemo na implementaciju MVP-a korak po korak.
