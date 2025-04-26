# RoonFileTagger

A Ruby application for tagging audio files with metadata.

## Prerequisites

- Ruby (2.7 or higher)
- Bundler (`gem install bundler`)
- TagLib library (for taglib-ruby gem)

### Installing TagLib on macOS

```bash
brew install taglib
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/anandhan/RoonFileTagger.git
cd RoonFileTagger
```

2. Install dependencies:
```bash
bundle install
```

3. Configure the scan directories:
   - Edit `config/scan_directories.txt` to add the paths of directories you want to scan
   - Each directory path should be on a new line

4. Configure the application:
   - Edit `config.yml` to adjust settings like:
     - File patterns to scan
     - Number of parallel threads
     - Logging level

## Usage

Run the application:
```bash
ruby lib/roon_tagger.rb
```

## Configuration

### scan_directories.txt
Add the paths of directories containing audio files you want to process. One path per line.

### config.yml
- `audio_file_patterns`: File extensions to scan (e.g., *.mp3, *.flac)
- `parallel`: Thread settings for parallel processing
- `logging`: Log file location and level

## Logging

Logs are stored in the `logs` directory. The main log file is `roon_tagger.log`.

## Features

- Recursively scans directories for audio files
- Supports name corrections for composers and album artists using JSON files
- Parallel processing for faster tagging
- Configurable through YAML file
- Detailed logging
- Supports multiple audio formats (MP3, FLAC, M4A)

## Name Corrections

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

## Contributing

Feel free to submit issues and enhancement requests.