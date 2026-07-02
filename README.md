# Kuharica (recepie-book)

Osobna, offline-first digitalna zbirka recepata. Bez logina, bez backend-a,
bez social/multi-user funkcionalnosti — privatni recipe manager za jednu
osobu, s velikim fotografijama hrane, korak-po-korak editorom recepta i
distraction-free "Cook mode" za praćenje recepta dok kuhaš.

Live demo (GitHub Pages, build iz `/docs`): `https://<user>.github.io/recepie-book/`

## Značajke

### Recepti
- Lista recepata (grid) s pretragom po nazivu/opisu i filterima (favoriti,
  vrijeme pripreme, tag)
- Dodavanje i uređivanje recepta kroz 2-koračni wizard (Osnovni podaci →
  Sastojci & Postupak)
- Detalji recepta: hero slika, sastojci, koraci pripreme, tagovi, statistike
  (vrijeme, porcije, broj sastojaka)
- **Skaliranje porcija** — stepper na broju porcija preračunava količine
  svih sastojaka uživo (i količine poslane u shopping listu); vrijedi samo
  za trenutni prikaz, ne mijenja spremljeni recept
- Favoriti
- Galerija slika po receptu (masonry grid + fullscreen swipe/zoom preglednik)
- **Verzioniranje recepata** — svaki save (kreiranje ili uređivanje) stvara
  novu verziju; timeline prikaz s diff-om dodanih/uklonjenih sastojaka
  između verzija i mogućnost vraćanja na stariju verziju (uz automatski
  backup trenutnog stanja prije vraćanja)
- **Cook mode** — fullscreen, korak-po-korak vođenje kroz pripremu, tajmer
  po koraku, drži ekran budnim (wakelock) dok je aktivan

### Tagovi
- Dodavanje/uklanjanje taga na receptu (kreiranje novog ili odabir
  postojećeg)
- Zaseban ekran za pregled i brisanje tagova

### Shopping lista
- Ručno dodavanje namirnica ili slanje sastojaka izravno iz recepta
- Automatsko spajanje istih namirnica (isti naziv + jedinica) zbrajanjem
  količina, umjesto duplih redova
- Checkbox za kupljeno, grupiranje po kategoriji, brisanje pojedinačne
  stavke i masovno čišćenje kupljenih stavki

### Slike
- Dodavanje jedne ili više slika po receptu, označavanje naslovne slike
- Na nativnim platformama slike se spremaju kao datoteke u app-ovom
  dokument direktoriju; na webu (gdje nema pravog datotečnog sustava) kao
  base64 `data:` URL izravno u bazi — isti stupac, bez promjene sheme

### Navigacija / UI
- Trajni bottom tab bar (Home / Recepti / Shopping / Postavke) + plutajući
  "+" gumb za brzo dodavanje
- Splash ekran, Home s "Nedavno dodano" i "Omiljeni" pregledom
- Postavke (Backup/Import/Export su za sada samo UI redovi bez logike)
- **Svijetla/tamna tema** (+ prati postavku sustava), birač u Postavke →
  Izgled → Tema; odabir se pamti preko `shared_preferences`
- Dizajn sustav usklađen s Figma predloškom (Newsreader + Hanken Grotesque
  fontovi, topla krem/narančasta paleta) — vidi `lib/design/`. Boje se
  čitaju preko `context.colors`/`context.typography`
  (`ThemeExtension<AppColorPalette>` registriran u `app.dart`), nikad kao
  statične konstante, kako bi se pratila aktivna tema

## Tech stack

- **Flutter** (web target aktivan; struktura je spremna i za mobile/desktop)
- **State management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod`) —
  `StateNotifier` + `StateNotifierProvider` po domeni (recepti, tagovi,
  shopping lista, verzije)
- **Navigacija:** [go_router](https://pub.dev/packages/go_router),
  `StatefulShellRoute.indexedStack` za bottom tab shell
- **Baza:** SQLite
  - Nativno: [`sqflite`](https://pub.dev/packages/sqflite)
  - Web: [`sqflite_common_ffi_web`](https://pub.dev/packages/sqflite_common_ffi_web)
    (pravi SQLite kompajliran u WASM, ne IndexedDB emulacija — `sqlite3.wasm`
    i pripadajući `sqflite_sw.js` worker vendirani su lokalno pod `web/`,
    bez runtime dohvata s vanjskog hosta)
- **Slike:** [`image_picker`](https://pub.dev/packages/image_picker),
  [`path_provider`](https://pub.dev/packages/path_provider) (nativno)
- **Fontovi:** [`google_fonts`](https://pub.dev/packages/google_fonts)
  (Newsreader, Hanken Grotesque)
- **Cook mode wakelock:** [`wakelock_plus`](https://pub.dev/packages/wakelock_plus)
- **ID-evi:** [`uuid`](https://pub.dev/packages/uuid) (UUID v4 stringovi
  umjesto auto-increment int-ova — lakše za buduću sinkronizaciju)

## Arhitektura

Jednostavna slojevita arhitektura po feature-ima — **ne** puni Clean
Architecture (bez use-case sloja) jer je riječ o osobnoj offline aplikaciji
bez alternativnih data source-ova. Detaljno obrazloženje u
[`ARCHITECTURE.md`](ARCHITECTURE.md), puna SQL shema u
[`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md).

```
UI (features/*)
   ↓
Providers / Notifiers (Riverpod state)
   ↓
Repositories (jedan po entitetu)
   ↓
DatabaseHelper (sqflite / sqflite_common_ffi_web) + ImageStorageService
```

```
lib/
├── app.dart                 # MaterialApp.router + go_router rute
├── main.dart                 # entry point, globalno hvatanje grešaka
├── core/
│   ├── database/              # DatabaseHelper (singleton), migracije
│   └── storage/                # ImageStorageService (native file / web data: URL)
├── design/                    # Design tokeni (boje, tipografija, spacing) + komponente
├── models/                    # Recipe, Ingredient, RecipeStep, RecipeImage, Tag,
│                               # RecipeVersion, RecipeSnapshot, ShoppingListItem, ...
├── repositories/              # CRUD nad SQLite (RecipeRepository, TagRepository, ...)
├── providers/                 # Riverpod state (notifier + state + provider po domeni)
├── widgets/                    # Dijeljeni widgeti (npr. RecipeImageThumbnail)
└── features/                   # Ekrani, grupirani po funkcionalnosti
    ├── shell/                    # AppShell — bottom tab bar + FAB
    ├── splash/, home/
    ├── recipe_list/, recipe_detail/, recipe_form/, recipe_versions/
    ├── gallery/, cook_mode/
    ├── shopping_list/, tags/, settings/
```

### Baza podataka

SQLite s FK cascade brisanjem: `recipes` → `ingredients`, `recipe_steps`,
`recipe_images`, `recipe_tags`, `recipe_versions` (sve `ON DELETE CASCADE`).
`shopping_list_items` je neovisan o receptu (`recipe_id` nullable,
`ON DELETE SET NULL`). Migracije su plain SQL stringovi u
`lib/core/database/migrations/migration_v1.dart`, primijenjene kroz
`DatabaseHelper` (singleton, `onCreate`/`onUpgrade`).

### Web deployment (GitHub Pages)

Build se generira u `/docs` na `main` grani i GitHub Pages ga servira
izravno:

```bash
flutter build web --release --base-href=/recepie-book/
python3 tool/patch_canvaskit_local.py build/web/flutter_bootstrap.js
rm -rf docs && mkdir docs && cp -r build/web/* docs/
```

`patch_canvaskit_local.py` je nužan post-build korak — `flutter build web`
svaki put iznova generira `flutter_bootstrap.js` pa se ne može trajno
prilagoditi kroz `web/` source (bio bi prebrisan). Skripta preusmjeri
CanvasKit učitavanje na već ubundlani lokalni `canvaskit/` folder umjesto
Googleovog CDN-a, kako aplikacija ne bi ovisila o vanjskom hostu.

`sqlite3.wasm` i `sqflite_sw.js` su vendirani direktno pod `web/` (isto
tako služeni same-origin, bez runtime fetcha s vanjskog hosta) —
vidi git history za kontekst zašto je to bitno (raniji pokušaj s
vanjskim URL-om je nepouzdano pucao u produkciji).

## Pokretanje

```bash
flutter pub get
flutter run -d chrome            # web
flutter build web --release --base-href=/recepie-book/   # produkcijski build
```

## Poznata ograničenja

- Fontovi (Newsreader, Hanken Grotesque) se i dalje dohvaćaju s Google Fonts
  CDN-a u runtimeu (graciozno pada natrag na sistemski font ako CDN nije
  dostupan) — nisu lokalno vendirani kao CanvasKit/SQLite wasm.
- Postavke → Backup/Import/Export su trenutno samo UI, bez implementirane
  logike.
- `flutter test` može pucati u nekim sandboxanim/offline build okruženjima
  zbog `sqlite3` paketovog native-asset build hooka (pokušava preuzeti
  host binarku) — ne utječe na `flutter build web`.
