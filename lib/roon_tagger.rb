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
    @config = YAML.load_file(config_path)
    setup_logger
    @file_scanner = FileScanner.new(@config)
    @audio_tagger = AudioTagger.new(@config)
    @name_corrector = NameCorrector.new(@config['name_correction_file'])
  end

  def run
    @logger.info("Starting RoonTagger")
    
    # Scan for audio files
    audio_files = @file_scanner.scan
    
    # Process files in parallel
    Parallel.each(audio_files, in_threads: 4) do |file|
      begin
        process_file(file)
      rescue => e
        @logger.error("Error processing #{file}: #{e.message}")
      end
    end
    
    @logger.info("RoonTagger completed")
  end

  private

  def setup_logger
    log_dir = File.dirname(@config['logging']['file'])
    FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
    
    @logger = Logger.new(@config['logging']['file'])
    @logger.level = Logger.const_get(@config['logging']['level'])
  end

  def process_file(file)
    @logger.info("Processing file: #{file}")
    
    # Get directory name for album info
    album_name = File.basename(File.dirname(file))
    
    # Get metadata from Gracenote
    metadata = @audio_tagger.fetch_metadata(album_name)
    
    # Correct names using the correction file
    corrected_metadata = @name_corrector.correct_names(metadata)
    
    # Apply tags to the file
    @audio_tagger.apply_tags(file, corrected_metadata)
    
    @logger.info("Successfully processed: #{file}")
  end
end 