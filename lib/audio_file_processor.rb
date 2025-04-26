def process_file(file_path)
    @logger.info("Processing file: #{file_path}")
    
    # Extract album name from directory
    album_name = File.dirname(file_path).split('/').last
    
    # Fetch metadata from TheAudioDB
    metadata = @tagger.fetch_metadata(album_name, file_path)
    
    # Apply name corrections if needed
    metadata = apply_name_corrections(metadata)
    
    # Apply tags to the file
    @tagger.apply_tags(file_path, metadata)
    
    @logger.info("Successfully processed: #{file_path}")
  rescue StandardError => e
    @logger.error("Error processing #{file_path}: #{e.message}")
    @logger.error(e.backtrace.join("\n"))
  end 