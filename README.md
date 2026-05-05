# SoundMagic 🎙🗺

Nahraj zvuky prírody a umiestni ich ako piny na mape.

## Štruktúra projektu

```
lib/
  main.dart                  # Entry point
  models/
    sound_pin.dart           # Model pre zvukový pin
    pin_storage.dart         # Ukladanie pinov do JSON
  screens/
    map_screen.dart          # Hlavná mapa + logika nahrávania
  widgets/
    mini_player.dart         # Prehrávač (bottom sheet)
    record_button.dart       # Animované tlačidlo nahrávania
ios/
  Runner/
    Info.plist               # iOS permissions (mikrofón, GPS)
```

## Setup

### 1. Závislosti
```bash
flutter pub get
```

### 2. iOS – dôležité
- V Xcode nastav **Bundle Identifier** (napr. `com.tvoje-meno.soundmagic`)
- Nastav **Signing Team** pre sideloading
- iOS deployment target: **13.0+**

### 3. Build cez Codemagic
1. Pripoj repozitár na [codemagic.io](https://codemagic.io)
2. Vyber **Flutter App** workflow
3. Platform: **iOS**
4. Build: `flutter build ipa --release`
5. Stiahni `.ipa` zo Codemagic artifacts

### 4. Inštalácia cez Sideloadly
1. Otvor [Sideloadly](https://sideloadly.io)
2. Pretiahni `.ipa` súbor
3. Zadaj Apple ID
4. Klikni **Start**
5. Na iPhone: **Nastavenia → Všeobecné → VPN a správa zariadení → dôveruj certifikátu**

## Funkcie v tejto verzii

- 🗺 OpenStreetMap mapa (bez API kľúča)
- 📍 GPS poloha v reálnom čase
- 🎙 Nahrávanie zvuku (AAC formát)
- 🔊 Mini prehrávač s progress barom
- 🗑 Mazanie pinov
- 💾 Lokálne ukladanie (prežije reštart appky)

## Plánované funkcie
- [ ] Reverse geocoding (názov miesta)
- [ ] Filter pinov podľa dátumu
- [ ] Zdieľanie nahrávok
- [ ] Waveform vizualizácia
