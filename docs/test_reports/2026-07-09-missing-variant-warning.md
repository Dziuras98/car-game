# Missing Variant Warning

## Zakres

- `scripts/game/game_manager.gd`
- Dodano ostrzezenie diagnostyczne dla brakujacego `car_variant_id` w katalogowej sciezce wyboru auta.

## Zachowanie

- Fallback do indeksu `0` zostal zachowany.
- Sciezka bez katalogu aut, gdzie `car_variant_id` jest parsowany jako stringowy indeks, zostala bez zmian.
- Publiczne API i wybor auta nie zostaly zmienione.
- Gameplay, fizyka, tuning, AI, tor, input i menu flow nie byly zmieniane.

## Walidacja

- `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`: passed
  - Wynik: `[SMOKE] Extended full program smoke test passed: 79 checks`
  - Uwaga: sandboxowe uruchomienie Godota zakonczylo sie natywnym crashem przed startem testu; powyzszy wynik pochodzi z uruchomienia unsandboxed.
- `git diff --check`: passed
