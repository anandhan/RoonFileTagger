require 'yaml'
require 'fileutils'
require 'logger'
require 'taglib'
require 'httparty'
require 'nokogiri'
require 'parallel'
require_relative 'file_scanner'
require_relative 'audio_tagger'
require_relative 'name_corrector'

class RoonTagger
  def initialize(config_path = 'config.yml')
    puts "Loading configuration from #{config_path}"
    @config = YAML.load_file(config_path)
    setup_logger
    @file_scanner = FileScanner.new(@config)
    @audio_tagger = AudioTagger.new(@config)
    @name_corrector = NameCorrector.new(@config['name_correction_file'])
    puts "Initialization complete"
  end

  def run
    puts "Starting RoonTagger"
    @logger.info("Starting RoonTagger")
    @logger.info("Configuration loaded from #{@config['scan_directories_file']}")
    
    # Scan for audio files
    puts "Scanning for audio files..."
    @logger.info("Scanning for audio files...")
    audio_files = @file_scanner.scan
    puts "Found #{audio_files.size} audio files to process"
    @logger.info("Found #{audio_files.size} audio files to process")
    
    # Process files in parallel
    puts "Starting parallel processing with 4 threads"
    @logger.info("Starting parallel processing with 4 threads")
    processed_count = 0
    total_files = audio_files.size
    
    Parallel.each(audio_files, in_threads: 4) do |file|
      begin
        process_file(file)
        processed_count += 1
        puts "Progress: #{processed_count}/#{total_files} files processed (#{(processed_count.to_f/total_files*100).round(2)}%)"
        @logger.info("Progress: #{processed_count}/#{total_files} files processed (#{(processed_count.to_f/total_files*100).round(2)}%)")
      rescue => e
        puts "Error processing #{file}: #{e.message}"
        puts e.backtrace
        @logger.error("Error processing #{file}: #{e.message}")
        @logger.error(e.backtrace.join("\n"))
      end
    end
    
    puts "RoonTagger completed"
    puts "Successfully processed #{processed_count} out of #{total_files} files"
    @logger.info("RoonTagger completed")
    @logger.info("Successfully processed #{processed_count} out of #{total_files} files")
  end

  private

  def setup_logger
    log_dir = File.dirname(@config['logging']['file'])
    FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
    
    @logger = Logger.new(@config['logging']['file'])
    @logger.level = Logger.const_get(@config['logging']['level'])
    
    # Add timestamp to log messages
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
    end
    puts "Logger setup complete"
  end

  def process_file(file)
    puts "Processing file: #{file}"
    @logger.info("Processing file: #{file}")
    
    # Get directory name for album info
    album_name = File.basename(File.dirname(file))
    puts "Album name derived from directory: #{album_name}"
    @logger.debug("Album name derived from directory: #{album_name}")
    
    # Get metadata from TheAudioDB
    puts "Fetching metadata from TheAudioDB for album: #{album_name}"
    @logger.debug("Fetching metadata from TheAudioDB for album: #{album_name}")
    metadata = @audio_tagger.fetch_metadata(album_name)
    puts "Retrieved metadata: #{metadata.inspect}"
    @logger.debug("Retrieved metadata: #{metadata.inspect}")
    
    # Correct names using the correction file
    puts "Applying name corrections"
    @logger.debug("Applying name corrections")
    corrected_metadata = @name_corrector.correct_names(metadata)
    puts "Corrected metadata: #{corrected_metadata.inspect}"
    @logger.debug("Corrected metadata: #{corrected_metadata.inspect}")
    
    # Apply tags to the file
    puts "Applying tags to file"
    @logger.debug("Applying tags to file")
    @audio_tagger.apply_tags(file, corrected_metadata)
    
    puts "Successfully processed: #{file}"
    @logger.info("Successfully processed: #{file}")
  end
end

# Create and run the tagger if this file is being run directly
if __FILE__ == $0
  tagger = RoonTagger.new
  tagger.run
end 