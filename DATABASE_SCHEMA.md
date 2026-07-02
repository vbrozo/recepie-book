# Recipe Book — SQLite database schema

Detaljna shema za sve entitete iz `ARCHITECTURE.md`. ID-evi su `TEXT`
(UUID v4). Datumi se spremaju kao `TEXT` u ISO8601 formatu (`sqflite` nema
nativni `DATETIME` tip — SQLite je dynamically typed, `TEXT` je standardna
konvencija). `created_at`/`updated_at` su dodani samo na tablice gdje redovi
stvarno mogu biti naknadno mijenjani (ne na "append-only" ili čisto
relacijske tablice).

## recipes

Glavni entitet — jedan recept.

| Kolona              | Tip     | Constraint                          |
|---------------------|---------|--------------------------------------|
| id                  | TEXT    | PRIMARY KEY                         |
| title               | TEXT    | NOT NULL                            |
| description         | TEXT    |                                      |
| servings            | INTEGER |                                      |
| prep_time_minutes   | INTEGER |                                      |
| cook_time_minutes   | INTEGER |                                      |
| is_favorite         | INTEGER | NOT NULL DEFAULT 0 (0/1)             |
| created_at          | TEXT    | NOT NULL (ISO8601)                  |
| updated_at          | TEXT    | NOT NULL (ISO8601)                  |

Indeksi: `title` (search), `is_favorite` (filter favorita).

## ingredients

Sastojak vezan uz recept. `updated_at` ima smisla jer korisnik može naknadno
mijenjati količinu/naziv sastojka bez brisanja retka.

| Kolona      | Tip     | Constraint                                          |
|-------------|---------|------------------------------------------------------|
| id          | TEXT    | PRIMARY KEY                                          |
| recipe_id   | TEXT    | NOT NULL, FK → recipes(id) ON DELETE CASCADE          |
| name        | TEXT    | NOT NULL                                             |
| quantity    | REAL    |                                                       |
| unit        | TEXT    |                                                       |
| sort_order  | INTEGER | NOT NULL DEFAULT 0                                   |
| created_at  | TEXT    | NOT NULL                                             |
| updated_at  | TEXT    | NOT NULL                                             |

Indeksi: `recipe_id` (dohvat svih sastojaka recepta, najčešći upit).

## recipe_steps

Korak pripreme.

| Kolona            | Tip     | Constraint                                          |
|-------------------|---------|--------------------------------------------------------|
| id                | TEXT    | PRIMARY KEY                                          |
| recipe_id         | TEXT    | NOT NULL, FK → recipes(id) ON DELETE CASCADE          |
| step_number       | INTEGER | NOT NULL                                             |
| instruction       | TEXT    | NOT NULL                                             |
| duration_minutes  | INTEGER |                                                       |
| created_at        | TEXT    | NOT NULL                                             |
| updated_at        | TEXT    | NOT NULL                                             |

Indeksi: `recipe_id`.

## recipe_images

Slika recepta (fizički fajl je na disku, ovdje samo relativna putanja —
vidi `ARCHITECTURE.md` §5).

| Kolona      | Tip     | Constraint                                          |
|-------------|---------|--------------------------------------------------------|
| id          | TEXT    | PRIMARY KEY                                          |
| recipe_id   | TEXT    | NOT NULL, FK → recipes(id) ON DELETE CASCADE          |
| file_path   | TEXT    | NOT NULL (relativna putanja)                         |
| is_primary  | INTEGER | NOT NULL DEFAULT 0 (0/1)                              |
| sort_order  | INTEGER | NOT NULL DEFAULT 0                                   |
| created_at  | TEXT    | NOT NULL                                             |
| updated_at  | TEXT    | NOT NULL (mijenja se npr. is_primary/sort_order)      |

Indeksi: `recipe_id`.

## tags

Naziv taga je jedinstven (case-sensitive na SQLite razini; normalizacija
velikih/malih slova radi se u repository sloju prije insert/lookup).

| Kolona      | Tip  | Constraint             |
|-------------|------|--------------------------|
| id          | TEXT | PRIMARY KEY             |
| name        | TEXT | NOT NULL UNIQUE          |
| created_at  | TEXT | NOT NULL                |
| updated_at  | TEXT | NOT NULL (rename taga)   |

Indeksi: `name` (implicitan preko UNIQUE constrainta, dodatan eksplicitan
indeks nije potreban).

## recipe_tags

Join tablica za many-to-many recipe ↔ tag. Nema `updated_at` — veza ili
postoji ili ne postoji, ne mijenja se, samo se briše/dodaje. `created_at`
zadržan radi mogućnosti sortiranja "nedavno dodani tagovi".

| Kolona      | Tip  | Constraint                                     |
|-------------|------|--------------------------------------------------|
| recipe_id   | TEXT | NOT NULL, FK → recipes(id) ON DELETE CASCADE    |
| tag_id      | TEXT | NOT NULL, FK → tags(id) ON DELETE CASCADE       |
| created_at  | TEXT | NOT NULL                                        |

Primary key: composite `(recipe_id, tag_id)`.

Indeksi: `tag_id` (obrnuti smjer upita — "svi recepti s ovim tagom"; PK već
pokriva `recipe_id` kao vodeću kolonu).

## recipe_versions

Append-only povijest snapshotova recepta. Nema `updated_at` jer je red
immutable nakon insertanja.

| Kolona          | Tip     | Constraint                                          |
|-----------------|---------|--------------------------------------------------------|
| id              | TEXT    | PRIMARY KEY                                          |
| recipe_id       | TEXT    | NOT NULL, FK → recipes(id) ON DELETE CASCADE          |
| version_number  | INTEGER | NOT NULL                                             |
| snapshot_json   | TEXT    | NOT NULL                                             |
| created_at      | TEXT    | NOT NULL                                             |

Indeksi: `recipe_id`. Dodatno: `UNIQUE(recipe_id, version_number)` da spriječi
duplicirane brojeve verzija za isti recept.

## shopping_list_items

Stavka liste za kupovinu — može ali ne mora biti vezana uz recept (ručno
dodane stavke imaju `recipe_id = NULL`).

| Kolona      | Tip     | Constraint                                          |
|-------------|---------|--------------------------------------------------------|
| id          | TEXT    | PRIMARY KEY                                          |
| name        | TEXT    | NOT NULL                                             |
| quantity    | REAL    |                                                       |
| unit        | TEXT    |                                                       |
| is_checked  | INTEGER | NOT NULL DEFAULT 0 (0/1)                              |
| recipe_id   | TEXT    | FK → recipes(id) ON DELETE SET NULL (nullable)        |
| created_at  | TEXT    | NOT NULL                                             |
| updated_at  | TEXT    | NOT NULL (check/uncheck, edit količine)               |

Indeksi: `recipe_id`, `is_checked` (filter "što je ostalo za kupiti").

---

Puna SQL migracija (CREATE TABLE + indeksi) je implementirana u
`lib/core/database/migrations/migration_v1.dart`, a otvara je i primjenjuje
`lib/core/database/database_helper.dart` (`DatabaseHelper`, singleton).
