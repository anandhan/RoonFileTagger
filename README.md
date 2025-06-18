# RoonFileTagger

A Ruby application for tagging audio files with metadata, optimized for use with the Roon music player.

## Prerequisites

- macOS (Intel or Apple Silicon)
- Homebrew (will be installed automatically if missing)
- Ruby 2.7 or higher (will be installed automatically if missing)

## Quick Installation

For a brand new machine, simply run:

```bash
git clone https://github.com/anandhan/RoonFileTagger.git
cd RoonFileTagger
chmod +x install.sh
./install.sh
```

The install script will automatically:
- Install Homebrew if missing
- Install Ruby 2.7+ if missing
- Install TagLib system library
- Install all Ruby dependencies (including the problematic `taglib-ruby` gem)
- Set up proper environment variables for Apple Silicon compatibility
- Create necessary directories and default configuration files
- Verify that everything is working correctly

## Manual Installation (if needed)

If you prefer manual installation or encounter issues:

1. **Install Homebrew** (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. **Install Ruby**:
```bash
brew install ruby
```

3. **Install TagLib**:
```bash
brew install taglib
```

4. **Install Ruby dependencies**:
```bash
gem install bundler
bundle install
```

## Configuration

### Scan Directories

You can configure scan directories in two ways:

**Option 1: JSON format (recommended)**
Edit `config/scan_directories.json`:
```json
[
  {
    "path": "/path/to/your/music/directory",
    "use_audiodb": false,
    "description": "Your music collection"
  }
]
```

**Option 2: Text format**
Edit `config/scan_directories.txt`:
```
/path/to/your/music/directory1
/path/to/your/music/directory2
```

### Application Settings

Edit `config.yml` to customize:
- File patterns to scan (MP3, FLAC, M4A, WAV)
- Number of parallel processing threads
- Logging level and file location
- AudioDB integration settings

## Usage

### Run the application:
```bash
ruby lib/roon_tagger.rb
```

### Or use the provided script:
```bash
chmod +x run_roon_tagger.sh
./run_roon_tagger.sh
```

## Features

- **Automated Setup**: One-command installation for new machines
- **Apple Silicon Compatible**: Works on both Intel and M1/M2/M3 Macs
- **Multiple Audio Formats**: Supports MP3, FLAC, M4A, and WAV
- **Parallel Processing**: Configurable multi-threading for faster processing
- **Name Corrections**: JSON-based artist/composer name standardization
- **Comprehensive Logging**: Detailed logs for troubleshooting
- **Flexible Configuration**: YAML-based settings and multiple directory formats

## Name Corrections

To standardize artist and composer names across albums:

1. Create a `name_to_use.json` file in the album directory
2. Add the correct name:

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
1. Scan specified directories for audio files
2. Look for `name_to_use.json` in each album directory
3. Apply the specified name as both composer and album artist tags
4. Process all audio files in parallel for efficiency

## Troubleshooting

### TagLib Installation Issues

If you encounter TagLib installation problems on Apple Silicon:

1. **Try Rosetta Terminal**: Open Terminal with Rosetta enabled and run the install script
2. **Use Docker**: Run the application in a Linux container
3. **Check Logs**: Review `logs/roon_tagger.log` for detailed error information

### Common Issues

- **No audio files found**: Check that your scan directories exist and contain audio files
- **Permission errors**: Ensure the application has read/write access to your music directories
- **TagLib errors**: Run `./install.sh` again to reinstall dependencies

## Logging

Logs are stored in the `logs` directory:
- `roon_tagger.log`: Main application log
- `cron.log`: Execution log (if using scheduled runs)

## Deployment

### For Production Servers

1. Clone the repository
2. Run `./install.sh` to set up dependencies
3. Configure scan directories in `config/scan_directories.json`
4. Set up cron jobs if needed using `run_roon_tagger.sh`

### For Development

The project includes comprehensive logging and error handling for easy debugging. Check the logs directory for detailed execution information.

## Contributing

Feel free to submit issues and enhancement requests. When contributing:

1. Test on both Intel and Apple Silicon Macs
2. Ensure the install script works on fresh machines
3. Update documentation for any new features

## License

This project is open source. See the repository for license details.