require 'json'
require 'logger'

class NameCorrector
  def initialize(logger)
    @logger = logger
  end

  def process_file(file)
    @logger.debug("Processing file: #{file}")
    
    album_directory = File.dirname(file)
    album_name = File.basename(album_directory)
    
    metadata = {
      album_directory: album_directory,
      album: album_name,
      title: File.basename(file, '.*').sub(/^\d+\s*-\s*/, '')
    }
    
    # First check for name_to_use.json
    json_path = File.join(album_directory, 'name_to_use.json')
    if File.exist?(json_path)
      begin
        json_data = JSON.parse(File.read(json_path))
        
        if json_data['name']
          @logger.info("Found name correction in #{json_path}: #{json_data['name']}")
          metadata[:album_artist] = json_data['name']
          metadata[:composer] = json_data['name']
          @logger.debug("Using name_to_use.json values for album_artist and composer")
          return metadata
        end
      rescue JSON::ParserError => e
        @logger.error("Error parsing name_to_use.json in #{album_directory}: #{e.message}")
      rescue StandardError => e
        @logger.error("Error processing name correction for #{file}: #{e.message}")
      end
    end
    
    @logger.debug("Final metadata: #{metadata.inspect}")
    metadata
  end
end 