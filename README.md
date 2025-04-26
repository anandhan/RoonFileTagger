# RoonFileTagger

A Ruby application that recursively scans directories for audio files and tags them using Gracenote metadata, with support for name corrections.

## Features

- Recursively scans directories for audio files
- Uses Gracenote API to fetch metadata
- Supports name corrections for artists and composers
- Parallel processing for faster tagging
- Configurable through YAML file
- Detailed logging

## Prerequisites

- Ruby 2.7 or higher
- Gracenote API credentials
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
5. Create a name corrections file at `config/name_corrections.txt`

## Configuration

### config.yml

```yaml
scan_directories:
  - "/path/to/your/music/library"

audio_file_patterns:
  - "*.mp3"
  - "*.flac"
  - "*.m4a"
  - "*.wav"

name_correction_file: "config/name_corrections.txt"

gracenote:
  client_id: "YOUR_CLIENT_ID"
  client_tag: "YOUR_CLIENT_TAG"

logging:
  level: "INFO"
  file: "logs/roon_tagger.log"
```

### Name Corrections File

Create a file at `config/name_corrections.txt` with the following format:
```
incorrect_name|correct_name
another_incorrect_name|another_correct_name
```

Example:
```
A.R. Rahman|A.R. Rahman
Ilayaraja|Ilaiyaraaja
```

## Usage

Run the application:
```bash
ruby lib/roon_tagger.rb
```

## Logging

Logs are written to the file specified in the configuration. Check this file for details about the tagging process and any errors that occur.

## Contributing

Feel free to submit issues and enhancement requests.