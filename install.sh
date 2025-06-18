#!/bin/bash

set -e

# Function to print messages
info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    info "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    info "Homebrew is already installed."
fi

# Check for Ruby (2.7 or higher)
if ! command -v ruby &> /dev/null; then
    info "Ruby not found. Installing Ruby via Homebrew..."
    brew install ruby
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
else
    RUBY_VERSION=$(ruby -e 'print RUBY_VERSION')
    if [[ $(echo -e "$RUBY_VERSION\n2.7" | sort -V | head -n1) != "2.7" ]]; then
        info "Ruby version is $RUBY_VERSION. Installing latest Ruby via Homebrew..."
        brew install ruby
        export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
    else
        info "Ruby version $RUBY_VERSION is installed."
    fi
fi

# Check for Bundler
gem list bundler -i > /dev/null 2>&1 || (info "Installing Bundler..." && gem install bundler)

# Robust TagLib installation
info "Setting up TagLib for audio file processing..."

# Function to check if taglib-ruby gem is working
check_taglib_ruby() {
    ruby -e "require 'taglib'; puts 'TagLib Ruby gem is working'" 2>/dev/null
}

# Function to install TagLib system library
install_taglib_system() {
    info "Installing TagLib system library..."
    brew install taglib
    
    # Set up environment variables for Apple Silicon
    export LDFLAGS="-L/opt/homebrew/opt/taglib/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/taglib/include"
    export PKG_CONFIG_PATH="/opt/homebrew/opt/taglib/lib/pkgconfig"
    
    # Also set for Intel Macs if needed
    if [[ -d "/usr/local/opt/taglib" ]]; then
        export LDFLAGS="$LDFLAGS -L/usr/local/opt/taglib/lib"
        export CPPFLAGS="$CPPFLAGS -I/usr/local/opt/taglib/include"
        export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/taglib/lib/pkgconfig"
    fi
}

# Function to install taglib-ruby gem with multiple fallback methods
install_taglib_ruby_gem() {
    info "Installing taglib-ruby gem..."
    
    # Method 1: Try with pkg-config
    if gem install taglib-ruby -- --use-pkg-config; then
        success "TagLib Ruby gem installed successfully with pkg-config"
        return 0
    fi
    
    # Method 2: Try with explicit paths
    if gem install taglib-ruby -- --with-taglib-dir=$(brew --prefix taglib); then
        success "TagLib Ruby gem installed successfully with explicit paths"
        return 0
    fi
    
    # Method 3: Try with include and lib paths
    if gem install taglib-ruby -- --with-taglib-include=/opt/homebrew/opt/taglib/include --with-taglib-lib=/opt/homebrew/opt/taglib/lib; then
        success "TagLib Ruby gem installed successfully with include/lib paths"
        return 0
    fi
    
    # Method 4: Try with Intel paths if on Apple Silicon
    if [[ $(uname -m) == "arm64" ]] && [[ -d "/usr/local/opt/taglib" ]]; then
        if gem install taglib-ruby -- --with-taglib-include=/usr/local/opt/taglib/include --with-taglib-lib=/usr/local/opt/taglib/lib; then
            success "TagLib Ruby gem installed successfully with Intel paths"
            return 0
        fi
    fi
    
    return 1
}

# Check if TagLib system library is installed
if ! brew list taglib &> /dev/null; then
    install_taglib_system
else
    info "TagLib system library is already installed."
    # Still set up environment variables
    export LDFLAGS="-L/opt/homebrew/opt/taglib/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/taglib/include"
    export PKG_CONFIG_PATH="/opt/homebrew/opt/taglib/lib/pkgconfig"
fi

# Check if taglib-ruby gem is working
if check_taglib_ruby; then
    success "TagLib Ruby gem is already working"
else
    # Try to install the gem
    if install_taglib_ruby_gem; then
        success "TagLib Ruby gem installed successfully"
    else
        error "Failed to install taglib-ruby gem with all methods"
        error "This might be due to Apple Silicon compatibility issues"
        error "Consider using Rosetta terminal or Docker for this project"
        exit 1
    fi
fi

# Verify TagLib is working
if check_taglib_ruby; then
    success "TagLib verification successful"
else
    error "TagLib verification failed after installation"
    exit 1
fi

# Install Ruby dependencies
info "Installing Ruby dependencies..."
bundle install

# Create necessary directories
mkdir -p logs
mkdir -p config

# Create default config files if they don't exist
if [ ! -f config.yml ] && [ ! -f config/config.yml ]; then
    info "Creating default config.yml..."
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

if [ ! -f config/scan_directories.txt ] && [ ! -f config/scan_directories.json ]; then
    info "Creating default scan_directories.txt..."
    echo "# Add your music directories here, one per line" > config/scan_directories.txt
fi

success "Installation complete!"
echo "\nNext steps:"
echo "1. Edit config/scan_directories.txt or config/scan_directories.json to add your music directories."
echo "2. Run the application with: ruby lib/roon_tagger.rb or ./run_roon_tagger.sh"
echo "\nIf you encounter TagLib issues on Apple Silicon, try:"
echo "- Using a Rosetta terminal"
echo "- Or using Docker with a Linux base image" 