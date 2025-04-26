class AudioTagger
  def initialize(config)
    @config = config
    @gracenote_config = config['gracenote']
  end

  def fetch_metadata(album_name)
    # Gracenote API endpoint
    url = "https://c#{@gracenote_config['client_id']}.web.cddbp.net/webapi/xml/1.0/"
    
    # Construct the query
    query = {
      client: @gracenote_config['client_id'],
      client_tag: @gracenote_config['client_tag'],
      album: album_name
    }
    
    # Make the API request
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

  def parse_metadata_response(xml_response)
    doc = Nokogiri::XML(xml_response)
    
    {
      artist: doc.at_xpath('//ARTIST')&.text,
      album: doc.at_xpath('//ALBUM')&.text,
      title: doc.at_xpath('//TITLE')&.text,
      composer: doc.at_xpath('//COMPOSER')&.text,
      genre: doc.at_xpath('//GENRE')&.text,
      year: doc.at_xpath('//YEAR')&.text
    }
  end
end 