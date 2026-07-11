# Localization contract

The user interface uses Polish source keys and provides Polish and English PO catalogs.

## Authoritative configuration

Catalog paths and the fallback locale are defined only in `project.godot`:

```text
internationalization/locale/translations
internationalization/locale/fallback
```

`LocalizationCatalogLoader` reads those settings, validates every catalog as a `Translation`, rejects duplicate locales, requires the fallback locale to have a configured catalog and registers each path at most once.

The current fallback is Polish (`pl`). Supported catalogs are:

```text
translations/pl.po
translations/en.po
```

## UI rules

- Literal user-facing strings in GDScript must be passed through `tr()`.
- Text serialized in `scenes/ui/*.tscn` must use a catalog key.
- Neutral values such as numbers, `km/h`, `RPM`, `N`, gear controls and arrow glyphs do not require translation.
- Dynamic labels must translate the format template before interpolation, for example:

```gdscript
label.text = tr("Okrążenie %d/%d") % [current_lap, total_laps]
```

- Every catalog must contain the same key set.
- Every translation must preserve the source format-placeholder sequence.
- Standard opponent node names remain internal. Results render them through `Kierowca %d` / `Driver %d`.

## Validation

`scripts/ci/validate_localization.ps1` runs before Godot is downloaded in the Windows workflow. It checks:

- translation paths declared by the project;
- duplicate paths and duplicate PO keys;
- key parity and non-empty values across catalogs;
- format-placeholder parity;
- literal `tr()` keys used by GDScript;
- serialized text in all UI scenes;
- direct literal text assignments in production UI/game/race scripts.

`scripts/tests/localization_test.gd` then validates imported `Translation` resources, supported locales, fallback behavior and representative menu, HUD, results, speedometer and mobile-control strings.

The packaged Windows smoke test switches to English and verifies that translated UI labels are present in the exported PCK, not only in editor/headless tests.
