# chroma-tuner

An iOS and iPadOS instrument tuning app with a skeuomorphic hardware-style interface.

## Features

- **Analog gauge** — Amber backlit display with note, frequency, and cent needle (−50 to +50)
- **LED indicators** — Flat (red) · In tune (green) · Sharp (red)
- **Chromatic tuning** — Real-time mic pitch detection; read-only note ring rotates to reflect intonation
- **Tone generator** — Rotatable note wheel with octave ± stepper and center play button
- **A4 calibration** — Tap ±1 Hz, long-press ±0.1 Hz (default 440 Hz)
- **Settings** — Reset A4, view tuning threshold

## Requirements

- iOS 17.0+
- iPhone and iPad
- Microphone access (chromatic tuning)

## Building

```bash
xcodegen generate
open ChromaTuner.xcodeproj
```

Test on a physical device for microphone pitch detection.
