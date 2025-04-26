require 'httparty'
require 'logger'

class AudioDBClient
  include HTTParty
  base_uri 'https://www.theaudiodb.com/api/v1/json'

  def initialize(config)
    @config = config
    @enabled = config['audiodb']['enabled']
    @retries = config['audiodb']['search_retries']
    @delay = config['audiodb']['search_delay']
    @logger = ::Logger.new(config['logging']['file'])
    @logger.level = ::Logger.const_get(config['logging']['level'])
  end

  def search_artist(artist_name)
    return nil unless @enabled

    @logger.info("Searching AudioDB for artist: #{artist_name}")
    attempts = 0

    begin
      response = self.class.get("/1/search.php", query: { s: artist_name })
      
      if response.success? && response['artists']
        artist = response['artists'].first
        @logger.info("Found artist: #{artist['strArtist']}")
        {
          name: artist['strArtist'],
          genre: artist['strGenre'],
          year_started: artist['intFormedYear'],
          biography: artist['strBiography']
        }
      else
        @logger.warn("No artist found for: #{artist_name}")
        nil
      end
    rescue => e
      attempts += 1
      if attempts < @retries
        @logger.warn("Retry #{attempts}/#{@retries} for #{artist_name}: #{e.message}")
        sleep @delay
        retry
      else
        @logger.error("Failed to fetch artist info for #{artist_name}: #{e.message}")
        nil
      end
    end
  end

  def search_album(album_name, artist_name = nil)
    return nil unless @enabled

    @logger.info("Searching AudioDB for album: #{album_name}")
    attempts = 0

    begin
      query = { a: album_name }
      query[:s] = artist_name if artist_name

      response = self.class.get("/1/searchalbum.php", query: query)
      
      if response.success? && response['album']
        album = response['album'].first
        @logger.info("Found album: #{album['strAlbum']}")
        {
          name: album['strAlbum'],
          artist: album['strArtist'],
          genre: album['strGenre'],
          year: album['intYearReleased'],
          description: album['strDescriptionEN']
        }
      else
        @logger.warn("No album found for: #{album_name}")
        nil
      end
    rescue => e
      attempts += 1
      if attempts < @retries
        @logger.warn("Retry #{attempts}/#{@retries} for #{album_name}: #{e.message}")
        sleep @delay
        retry
      else
        @logger.error("Failed to fetch album info for #{album_name}: #{e.message}")
        nil
      end
    end
  end
end 