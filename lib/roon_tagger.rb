require 'yaml'
require 'fileutils'
require 'logger'
require 'taglib'
require 'parallel'
require_relative 'file_scanner'
require_relative 'audio_tagger'
require_relative 'name_corrector'

class RoonTagger
  def initialize
    @config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'config.yml'))
    setup_logger
    @file_scanner = FileScanner.new(@logger)
    @audio_tagger = AudioTagger.new(@logger)
    @name_corrector = NameCorrector.new(@logger)
    @num_threads = @config['parallel']['threads'] || 4
  end

  def run
    puts "Starting RoonTagger..."
    @logger.info("Starting RoonTagger")
    
    # Load scan directories
    puts "Loading scan directories..."
    @logger.info("Loading scan directories")
    directories = @file_scanner.load_scan_directories
    puts "Found #{directories.size} directories to scan"
    @logger.info("Found #{directories.size} directories to scan")
    
    # Scan for audio files
    puts "Scanning for audio files..."
    @logger.info("Scanning for audio files")
    audio_files = @file_scanner.scan_directories(directories)
    puts "Found #{audio_files.size} audio files to process"
    @logger.info("Found #{audio_files.size} audio files to process")
    
    if audio_files.empty?
      puts "No audio files found to process"
      @logger.warn("No audio files found to process")
      return
    end
    
    # Process files in parallel
    puts "Processing files with #{@config['parallel']['threads']} threads..."
    @logger.info("Processing files with #{@config['parallel']['threads']} threads")
    
    Parallel.each(audio_files, in_threads: @config['parallel']['threads']) do |file|
      process_file(file)
    end
    
    puts "Processing complete"
    @logger.info("Processing complete")
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
    @logger.info("Processing file: #{file}")
    begin
      metadata = @name_corrector.process_file(file)
      if metadata
        if @audio_tagger.apply_tags(file, metadata)
          @logger.info("Successfully processed: #{file}")
        else
          @logger.error("Failed to apply tags to: #{file}")
        end
      else
        @logger.warn("No metadata corrections needed for: #{file}")
      end
    rescue StandardError => e
      @logger.error("Error processing #{file}: #{e.message}")
    end
  end
end

# Create and run the tagger if this file is being run directly
if __FILE__ == $0
  tagger = RoonTagger.new
  tagger.run
end 