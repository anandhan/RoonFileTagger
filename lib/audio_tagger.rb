require 'json'
require 'logger'
require 'taglib'

class AudioTagger
  def initialize(config)
    @config = config
    @logger = Logger.new(config['logging']['file'])
    @logger.level = Logger.const_get(config['logging']['level'])
  end

  def fetch_metadata(album_name, file_path)
    # Extract metadata from filename and directory structure
    extract_metadata_from_filename(file_path)
  end

  def apply_tags(file_path, metadata)
    return if metadata.nil? || metadata.empty?

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

  def extract_metadata_from_filename(file_path)
    # Extract directory name for album
    dir_name = File.dirname(file_path).split('/').last
    
    # Extract file name for title (remove extension and track number)
    file_name = File.basename(file_path, '.*')
    title = file_name.sub(/^\d+\s*-\s*/, '') # Remove track number prefix
    
    {
      artist: nil,  # Will be set by name_to_use.json if present
      album: dir_name,
      title: title,
      composer: nil,  # Will be set by name_to_use.json if present
      album_artist: nil,  # Will be set by name_to_use.json if present
      genre: nil,
      year: nil
    }
  end

  def apply_mp3_tags(file_path, metadata)
    @logger.debug("Applying tags to file: #{file_path}")
    @logger.debug("Tags to apply: #{metadata.inspect}")
    
    TagLib::FileRef.open(file_path) do |file|
      tag = file.tag
      
      # Only update composer and album artist if they are present
      if metadata[:composer]
        if file.is_a?(TagLib::MPEG::File)
          id3v2_tag = file.id3v2_tag(true)
          id3v2_tag.remove_frames('TCOM')
          frame = TagLib::ID3v2::TextIdentificationFrame.new('TCOM', TagLib::String::UTF8)
          frame.text = metadata[:composer]
          id3v2_tag.add_frame(frame)
        end
      end
      
      if metadata[:album_artist]
        if file.is_a?(TagLib::MPEG::File)
          id3v2_tag = file.id3v2_tag(true)
          id3v2_tag.remove_frames('TPE2')
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