class NameCorrector
  def initialize(config)
    @config = config
    @logger = Logger.new(config['logging']['file'])
    @logger.level = Logger.const_get(config['logging']['level'])
  end

  def correct_names(metadata)
    corrected = metadata.dup
    
    # Check for name_to_use.json in the album directory
    if metadata[:album_directory]
      name_to_use_file = File.join(metadata[:album_directory], 'name_to_use.json')
      if File.exist?(name_to_use_file)
        begin
          json_data = JSON.parse(File.read(name_to_use_file))
          if json_data['name']
            @logger.info("Using name correction from #{name_to_use_file}: #{json_data['name']}")
            corrected[:composer] = json_data['name']
            corrected[:album_artist] = json_data['name']
          end
        rescue JSON::ParserError => e
          @logger.error("Error parsing name_to_use.json at #{name_to_use_file}: #{e.message}")
        end
      end
    end
    
    corrected
  end
end 