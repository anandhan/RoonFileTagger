require 'json'

class AudioTagger
  def initialize(config)
    @config = config
    @name_corrections = load_name_corrections
    setup_logger
  end

  def fetch_metadata(album_name, file_path)
    # First try to get metadata from TheAudioDB
    metadata = fetch_from_audiodb(album_name)
    
    # If no metadata found, try to extract from filename
    if metadata.nil? || metadata.empty?
      metadata = extract_metadata_from_filename(file_path)
    end
    
    metadata
  end

  def apply_tags(file_path, metadata)
    return if metadata.nil? || metadata.empty?

    # Apply name corrections if needed
    metadata = apply_name_corrections(metadata)

    # Apply tags using appropriate tool based on file extension
    case File.extname(file_path).downcase
    when '.mp3'
      apply_mp3_tags(file_path, metadata)
    when '.flac'
      apply_flac_tags(file_path, metadata)
    when '.m4a'
      apply_m4a_tags(file_path, metadata)
    else
      @logger.warn("Unsupported file format: #{file_path}")
    end
  end

  private

  def load_name_corrections
    corrections = {}
    Dir.glob(File.join(@config['directories']['music'], '**', 'name_to_use.json')).each do |file|
      begin
        json_data = JSON.parse(File.read(file))
        if json_data['name']
          # Use the directory name as the key
          dir_name = File.dirname(file).split('/').last
          corrections[dir_name] = json_data['name']
        end
      rescue JSON::ParserError => e
        @logger.error("Error parsing name_to_use.json at #{file}: #{e.message}")
      end
    end
    corrections
  end

  def apply_name_corrections(metadata)
    return metadata unless metadata[:album]

    corrected_name = @name_corrections[metadata[:album]]
    if corrected_name
      metadata[:composer] = corrected_name
      metadata[:album_artist] = corrected_name
    end

    metadata
  end

  def setup_logger
    @logger = Logger.new(@config['logging']['file'])
    @logger.level = Logger.const_get(@config['logging']['level'])
  end

  def fetch_from_audiodb(album_name)
    # TheAudioDB API endpoint for album search
    url = "#{@config['theaudiodb']['base_url']}/#{@config['theaudiodb']['api_key']}/searchalbum.php"
    
    # Construct the query
    query = {
      s: album_name
    }
    
    @logger.debug("Fetching metadata from TheAudioDB for: #{album_name}")
    response = HTTParty.get(url, query: query)
    
    # Parse the response
    parse_metadata_response(response.body)
  end

  def parse_metadata_response(json_response)
    data = JSON.parse(json_response)
    
    # TheAudioDB returns an array of albums in the 'album' key
    if data['album'] && data['album'].any?
      album = data['album'].first
      
      metadata = {
        artist: album['strArtist'],
        album: album['strAlbum'],
        title: album['strTrack'] || nil,  # Might not be available in album search
        composer: nil,  # TheAudioDB doesn't provide composer info
        genre: album['strGenre'],
        year: album['intYearReleased']
      }
      
      @logger.debug("Parsed metadata: #{metadata.inspect}")
      metadata
    else
      @logger.warn("No metadata found for album")
      {
        artist: nil,
        album: nil,
        title: nil,
        composer: nil,
        genre: nil,
        year: nil
      }
    end
  end

  def extract_metadata_from_filename(file_path)
    # Extract directory name for album
    dir_name = File.dirname(file_path).split('/').last
    
    # Extract file name for title (remove extension and track number)
    file_name = File.basename(file_path, '.*')
    title = file_name.sub(/^\d+\s*-\s*/, '') # Remove track number prefix
    
    {
      artist: "Imman",  # Default artist
      album: dir_name,
      title: title,
      composer: nil,
      genre: nil,
      year: nil
    }
  end

  def apply_mp3_tags(file_path, metadata)
    @logger.debug("Applying tags to file: #{file_path}")
    @logger.debug("Tags to apply: #{metadata.inspect}")
    
    TagLib::FileRef.open(file_path) do |file|
      tag = file.tag
      # Only update composer and album artist
      if metadata[:composer]
        # Use ID3v2 specific API for composer tag
        if file.is_a?(TagLib::MPEG::File)
          id3v2_tag = file.id3v2_tag(true) # Create if not exists
          # Remove existing TCOM frames if any
          id3v2_tag.remove_frames('TCOM')
          # Create new composer frame
          frame = TagLib::ID3v2::TextIdentificationFrame.new('TCOM', TagLib::String::UTF8)
          frame.text = metadata[:composer]
          id3v2_tag.add_frame(frame)
        end
      end
      
      if metadata[:album_artist]
        # Use ID3v2 specific API for album artist tag
        if file.is_a?(TagLib::MPEG::File)
          id3v2_tag = file.id3v2_tag(true) # Create if not exists
          # Remove existing TPE2 frames if any
          id3v2_tag.remove_frames('TPE2')
          # Create new album artist frame
          frame = TagLib::ID3v2::TextIdentificationFrame.new('TPE2', TagLib::String::UTF8)
          frame.text = metadata[:album_artist]
          id3v2_tag.add_frame(frame)
        end
      end
      
      file.save
    end
    
    @logger.debug("Tags applied successfully")
  end

  def apply_flac_tags(file_path, metadata)
    # Implementation for FLAC tags
    @logger.warn("FLAC tags application not implemented")
  end

  def apply_m4a_tags(file_path, metadata)
    # Implementation for M4A tags
    @logger.warn("M4A tags application not implemented")
  end
end 