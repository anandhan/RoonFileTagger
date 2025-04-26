class AudioTagger
  def initialize(config)
    @config = config
    @api_config = config['theaudiodb']
  end

  def fetch_metadata(album_name)
    # TheAudioDB API endpoint for album search
    url = "#{@api_config['base_url']}/#{@api_config['api_key']}/searchalbum.php"
    
    # Construct the query - we'll use a simple search for now
    # You might want to split album_name into artist and album parts for better results
    query = {
      s: album_name
    }
    
    @logger.debug("Fetching metadata from TheAudioDB for: #{album_name}")
    response = HTTParty.get(url, query: query)
    
    # Parse the response
    parse_metadata_response(response.body)
  end

  def apply_tags(file_path, metadata)
    TagLib::FileRef.open(file_path) do |file|
      tag = file.tag
      
      tag.artist = metadata[:artist]
      tag.album = metadata[:album]
      tag.title = metadata[:title]
      tag.composer = metadata[:composer]
      tag.genre = metadata[:genre]
      tag.year = metadata[:year]
      
      file.save
    end
  end

  private

  def parse_metadata_response(json_response)
    data = JSON.parse(json_response)
    
    # TheAudioDB returns an array of albums in the 'album' key
    if data['album'] && data['album'].any?
      album = data['album'].first
      
      {
        artist: album['strArtist'],
        album: album['strAlbum'],
        title: album['strTrack'] || nil,  # Might not be available in album search
        composer: nil,  # TheAudioDB doesn't provide composer info
        genre: album['strGenre'],
        year: album['intYearReleased']
      }
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