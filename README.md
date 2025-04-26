# RoonFileTagger

A Ruby application that recursively scans directories for audio files and tags them with metadata, with a focus on name corrections using JSON files.

## Features

- Recursively scans directories for audio files
- Supports name corrections for composers and album artists using JSON files
- Parallel processing for faster tagging
- Configurable through YAML file
- Detailed logging
- Supports multiple audio formats (MP3, FLAC, M4A)

## Prerequisites

- Ruby 2.7 or higher
- TagLib development libraries

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Install TagLib development libraries:
   - macOS: `brew install taglib`
   - Ubuntu/Debian: `sudo apt-get install libtag1-dev`
   - Fedora: `sudo dnf install taglib-devel`

4. Create a `config.yml` file (see example below)

## Configuration

### config.yml

```yaml
# Directory settings
scan_directories_file: "config/scan_directories.txt"  # File containing list of directories to scan

# File patterns to scan
audio_file_patterns:
  - "*.mp3"
  - "*.flac"
  - "*.m4a"
  - "*.wav"

# Logging settings
logging:
  level: "INFO"
  file: "logs/roon_tagger.log"
```

### Scan Directories

Create a file at `config/scan_directories.txt` with the following format:
```
# Lines starting with # are comments
/path/to/your/music/library1
/path/to/your/music/library2
```

### Name Corrections

To specify the correct name for a composer and album artist in an album directory:

1. Create a `name_to_use.json` file in the album directory
2. Add the correct name in the following format:

```json
{
  "name": "Correct Artist Name"
}
```

Example directory structure:
```
Music/
├── Album1/
│   ├── name_to_use.json  # {"name": "A.R. Rahman"}
│   ├── 01 - Song1.mp3
│   └── 02 - Song2.mp3
└── Album2/
    ├── name_to_use.json  # {"name": "Ilaiyaraaja"}
    ├── 01 - Track1.mp3
    └── 02 - Track2.mp3
```

The application will:
1. Find all audio files in the specified directories
2. Look for `name_to_use.json` in each album directory
3. If found, use the specified name for both composer and album artist tags
4. Apply the tags to all audio files in that directory

## Usage

Run the application:
```bash
ruby lib/roon_tagger.rb
```

## Logging

Logs are written to the file specified in the configuration. Check this file for details about the tagging process and any errors that occur.

## Contributing

Feel free to submit issues and enhancement requests.