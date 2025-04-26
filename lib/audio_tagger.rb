require 'json'

class AudioTagger
  def initialize(config)
    @config = config
    @api_config = config['theaudiodb']
    setup_logger
  end

  def fetch_metadata(album_name, file_path)
    # TheAudioDB API endpoint for album search
    url = "#{@api_config['base_url']}/#{@api_config['api_key']}/searchalbum.php"
    
    # Construct the query
    query = {
      s: album_name
    }
    
    @logger.debug("Fetching metadata from TheAudioDB for: #{album_name}")
    response = HTTParty.get(url, query: query)
    
    # Parse the response
    metadata = parse_metadata_response(response.body)
    
    # If no metadata found from TheAudioDB, use directory and file information
    if metadata[:artist].nil? || metadata[:album].nil?
      @logger.info("No metadata found from TheAudioDB, using directory information")
      
      # Extract directory name for album
      dir_name = File.dirname(file_path).split('/').last
      
      # Extract file name for title (remove extension and track number)
      file_name = File.basename(file_path, '.*')
      title = file_name.sub(/^\d+\s*-\s*/, '') # Remove track number prefix
      
      metadata = {
        artist: "Imman",  # Default artist
        album: dir_name,
        title: title,
        composer: nil,
        genre: nil,
        year: nil
      }
    end
    
    metadata
  end

  def apply_tags(file_path, metadata)
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

  private

  def setup_logger
    @logger = Logger.new(@config['logging']['file'])
    @logger.level = Logger.const_get(@config['logging']['level'])
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
end 