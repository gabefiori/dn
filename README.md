# Daily Notes
A simple CLI for quickly creating and editing daily notes.

It generates notes with the following structure:
```sh
notes
└── 2025
    ├── 05
    │   ├── 21.md
    │   └── 22.md
    └── 06
        ├── 10.md
        └── 12.md
```
and opens them in your terminal editor.

## Usage
To use the CLI, run the following command in your terminal:
```sh
dn
```

After running the command, the note for the day will open in your editor, as defined by the `EDITOR` environment variable.

## Configuration
Configuration values are fetched from the environment.

- `DAILY_NOTES_DIR`: The location of the notes. Defaults to `~/notes`.
- `EDITOR`: The editor in which the notes will be opened.

All options can be overridden by the CLI flags. For more information, run `dn --help`.

## Installation
```sh
make install
```
After that, the `dn` command should be available for use.

> [!WARNING]  
> Windows is not supported.
