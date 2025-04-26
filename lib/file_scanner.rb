require 'logger'
require 'taglib'
require 'json'

class FileScanner
  attr_reader :directories

  def initialize(logger)
    @logger = logger
    @directories = []
    @use_audiodb = {}
    @directory_metadata = {}
    @audio_patterns = ['*.flac', '*.mp3', '*.m4a', '*.wav']
  end

  def load_scan_directories
    puts "Loading scan directories from config/scan_directories.json"
    @logger.info("Loading scan directories from config/scan_directories.json")
    
    begin
      json_data = File.read('config/scan_directories.json')
      directories = JSON.parse(json_data)
      puts "Found #{directories.size} directories in config"
      @logger.info("Found #{directories.size} directories in config")
      
      directories.each do |dir|
        path = dir['path']
        puts "Checking directory: #{path}"
        @logger.info("Checking directory: #{path}")
        
        if File.directory?(path)
          puts "Directory exists: #{path}"
          @logger.info("Directory exists: #{path}")
          @directories << path
        else
          puts "Directory not found: #{path}"
          @logger.warn("Directory not found: #{path}")
        end
      end
      
      puts "Total valid directories to scan: #{@directories.size}"
      @logger.info("Total valid directories to scan: #{@directories.size}")
      @directories
    rescue JSON::ParserError => e
      puts "Error parsing scan_directories.json: #{e.message}"
      @logger.error("Error parsing scan_directories.json: #{e.message}")
      []
    rescue StandardError => e
      puts "Error loading scan directories: #{e.message}"
      @logger.error("Error loading scan directories: #{e.message}")
      []
    end
  end

  def scan_directories(directories)
    puts "Starting directory scan..."
    @logger.info("Starting directory scan")
    
    audio_files = []
    directories.each do |dir|
      puts "Scanning directory: #{dir}"
      @logger.info("Scanning directory: #{dir}")
      
      Dir.glob(File.join(dir, '**', '*.{flac,mp3,m4a}')).each do |file|
        puts "Found audio file: #{file}"
        @logger.info("Found audio file: #{file}")
        audio_files << file
      end
    end
    
    puts "Scan complete. Found #{audio_files.size} audio files"
    @logger.info("Scan complete. Found #{audio_files.size} audio files")
    audio_files
  end

  def scan
    @logger.info("Starting file scan")
    audio_files = []
    
    begin
      scan_dirs = load_scan_directories
      @logger.info("Loaded #{scan_dirs.size} directories to scan")
      
      scan_dirs.each do |dir|
        if Dir.exist?(dir)
          @logger.info("Scanning directory: #{dir}")
          @audio_patterns.each do |pattern|
            Dir.glob(File.join(dir, '**', pattern)).each do |file|
              @logger.debug("Found audio file: #{file}")
              audio_files << file
            end
          end
        else
          @logger.warn("Directory does not exist: #{dir}")
        end
      end
      
      @logger.info("Found #{audio_files.size} audio files")
      audio_files
      
    rescue StandardError => e
      @logger.error("Error during file scan: #{e.message}")
      []
    end
  end

  def use_audiodb_for?(directory)
    @use_audiodb[directory] || false
  end

  def get_directory_metadata(directory)
    @directory_metadata[directory] || {}
  end

  private

  def extract_metadata_from_directory(dir)
    # Extract metadata from directory name or structure
    {
      artist: nil,
      album: File.basename(dir),
      genre: nil,
      year: nil
    }
  end
end 