class AudioFileProcessor
  def initialize(config)
    @config = config
    @tagger = AudioTagger.new(config)
    setup_logger
  end

  def process_directory(directory)
    @logger.info("Processing directory: #{directory}")
    
    # Check for name_to_use.txt in the directory
    name_to_use_file = File.join(directory, 'name_to_use.txt')
    name_to_use = if File.exist?(name_to_use_file)
      @logger.info("Found name_to_use.txt in #{directory}")
      File.read(name_to_use_file).strip
    else
      @logger.info("No name_to_use.txt found in #{directory}")
      nil
    end

    # Process each audio file in the directory
    Dir.glob(File.join(directory, '*.{mp3,flac,m4a}')) do |file_path|
      process_file(file_path, name_to_use)
    end
  end

  def process_file(file_path, name_to_use)
    @logger.info("Processing file: #{file_path}")
    
    # Extract album name from directory
    album_name = File.dirname(file_path).split('/').last
    
    # Fetch metadata from TheAudioDB
    metadata = @tagger.fetch_metadata(album_name, file_path)
    
    # If we have a name_to_use, update only composer and album artist
    if name_to_use
      metadata[:composer] = name_to_use
      metadata[:album_artist] = name_to_use
    end
    
    # Apply tags to the file
    @tagger.apply_tags(file_path, metadata)
    
    @logger.info("Successfully processed: #{file_path}")
  rescue StandardError => e
    @logger.error("Error processing #{file_path}: #{e.message}")
    @logger.error(e.backtrace.join("\n"))
  end

  private

  def setup_logger
    @logger = Logger.new(@config['logging']['file'])
    @logger.level = Logger.const_get(@config['logging']['level'])
  end
end 