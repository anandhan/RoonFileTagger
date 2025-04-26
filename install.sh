#!/bin/bash

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "Ruby is not installed. Please install Ruby 2.7 or higher."
    exit 1
fi

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi

# Check if TagLib is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

if ! brew list taglib &> /dev/null; then
    echo "Installing TagLib..."
    brew install taglib
fi

# Install Ruby dependencies
echo "Installing Ruby dependencies..."
bundle install

# Create necessary directories
mkdir -p logs
mkdir -p config

# Create default config files if they don't exist
if [ ! -f config.yml ]; then
    echo "Creating default config.yml..."
    cat > config.yml << EOL
# Configuration for RoonFileTagger

# Directory settings
scan_directories_file: "config/scan_directories.txt"  # File containing list of directories to scan

# File patterns to scan
audio_file_patterns:
  - "*.mp3"
  - "*.flac"
  - "*.m4a"
  - "*.wav"

# Parallel processing settings
parallel:
  enabled: true
  threads: 4  # Number of threads to use for parallel processing

# Logging settings
logging:
  level: "INFO"
  file: "logs/roon_tagger.log"
EOL
fi

if [ ! -f config/scan_directories.txt ]; then
    echo "Creating default scan_directories.txt..."
    echo "# Add your music directories here, one per line" > config/scan_directories.txt
fi

echo "Installation complete!"
echo "Please edit config/scan_directories.txt to add your music directories." 