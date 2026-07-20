# Waykin Display Font

`WaykinDisplay-Regular.ttf` is generated from deterministic Python geometry and is intended for splash branding, section titles, and short companion-state headings.

## Build

```bash
python -m pip install fonttools
python tools/font/build_font.py
```

The generator writes:

```text
App/Resources/Fonts/WaykinDisplay-Regular.ttf
```

## Current coverage

- `A-Z`
- `0-9`
- space
- `. : - ' &`

This is deliberately a display subset. Body copy and accessibility-critical long text continue to use the system font.

## Identity

```yaml
family: Waykin Display
style: Regular
postscript_name: WaykinDisplay-Regular
version: 0.1
embedding_fsType: 0
# Regenerate with tools/font/build_font.py; verify with shasum -a 256.
sha256: 8ef0c71774ca4c5813ad3162690aec32723c0bb22c1028fb34ecdc16764c2d5f
```

## Design grammar

The face uses a five-column, seven-row geometric matrix with restrained chamfer variation. It is intentionally wide, modular, and legible at display sizes. The construction echoes Waykin's circular emblem and engineered/mystic visual language without replacing readable system typography throughout the app.

## Usage

```swift
Text("WAYKIN")
    .waykinDisplayTitle(size: 34, tracking: 5)
```

UIKit surfaces can use:

```swift
WaykinTypography.uiDisplay(size: 30)
```

The UIKit helper falls back to a medium-weight system font if registration fails. The unit test still fails when the bundled font is missing, preventing silent packaging regressions.
