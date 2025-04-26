require 'json'
require 'logger'
require 'taglib'

class AudioTagger
  def initialize(logger)
    @logger = logger
  end

  def apply_tags(file, metadata)
    @logger.debug("Applying tags to file: #{file}")
    @logger.debug("Metadata to apply: #{metadata.inspect}")
    
    begin
      TagLib::FLAC::File.open(file) do |flac|
        unless flac
          @logger.error("Failed to open FLAC file: #{file}")
          return false
        end
        
        tag = flac.tag
        unless tag
          @logger.error("Failed to get tag for file: #{file}")
          return false
        end
        
        # Apply basic tags
        tag.title = metadata[:title] if metadata[:title]
        tag.artist = metadata[:artist] if metadata[:artist]
        tag.album = metadata[:album] if metadata[:album]
        tag.year = metadata[:year].to_i if metadata[:year]
        tag.track = metadata[:track].to_i if metadata[:track]
        tag.genre = metadata[:genre] if metadata[:genre]
        
        # Apply xiph comments for additional fields
        if flac.xiph_comment
          if metadata[:album_artist]
            flac.xiph_comment.add_field('ALBUMARTIST', metadata[:album_artist])
          end
          
          if metadata[:composer]
            flac.xiph_comment.add_field('COMPOSER', metadata[:composer])
          end
        end
        
        unless flac.save
          @logger.error("Failed to save tags for file: #{file}")
          return false
        end
        
        @logger.info("Successfully applied tags to: #{file}")
        true
      end
    rescue StandardError => e
      @logger.error("Error applying tags to #{file}: #{e.message}")
      false
    end
  end

  private

  def extract_metadata_from_filename(file_path)
    dir_name = File.dirname(file_path).split('/').last
    file_name = File.basename(file_path, '.*')
    title = file_name.sub(/^\d+\s*-\s*/, '')
    
    {
      artist: nil,
      album: dir_name,
      title: title,
      composer: nil,
      album_artist: nil,
      genre: nil,
      year: nil
    }
  end

  def apply_mp3_tags(file_path, metadata)
    @logger.debug("Applying tags to file: #{file_path}")
    @logger.debug("Tags to apply: #{metadata.inspect}")
    
    TagLib::MPEG::File.open(file_path) do |file|
      tag = file.tag
      id3v2_tag = file.id3v2_tag(true)
      
      # Update basic tags
      tag.title = metadata[:title] if metadata[:title]
      tag.artist = metadata[:artist] if metadata[:artist]
      tag.album = metadata[:album] if metadata[:album]
      tag.genre = metadata[:genre] if metadata[:genre]
      tag.year = metadata[:year].to_i if metadata[:year]
      
      # Update composer if present
      if metadata[:composer]
        id3v2_tag.remove_frames('TCOM')
        frame = TagLib::ID3v2::TextIdentificationFrame.new('TCOM', TagLib::String::UTF8)
        frame.text = metadata[:composer]
        id3v2_tag.add_frame(frame)
      end
      
      # Update album artist if present
      if metadata[:album_artist]
        id3v2_tag.remove_frames('TPE2')
        frame = TagLib::ID3v2::TextIdentificationFrame.new('TPE2', TagLib::String::UTF8)
        frame.text = metadata[:album_artist]
        id3v2_tag.add_frame(frame)
      end
      
      file.save
    end
    
    @logger.debug("Tags applied successfully")
  end

  def apply_flac_tags(file_path, metadata)
    @logger.debug("Applying FLAC tags to: #{file_path}")
    @logger.debug("Metadata: #{metadata.inspect}")
    
    begin
      flac = TagLib::FLAC::File.new(file_path)
      unless flac.open
        @logger.error("Failed to open FLAC file: #{file_path}")
        return false
      end
      
      tags = flac.xiph_comment
      unless tags
        @logger.error("Failed to get FLAC tags: #{file_path}")
        return false
      end
      
      # Apply standard tags
      tags.title = metadata[:title] if metadata[:title]
      tags.artist = metadata[:artist] if metadata[:artist]
      tags.album = metadata[:album] if metadata[:album]
      tags.year = metadata[:year].to_i if metadata[:year]
      tags.track = metadata[:track].to_i if metadata[:track]
      tags.genre = metadata[:genre] if metadata[:genre]
      
      # Apply additional fields
      tags.album_artist = metadata[:album_artist] if metadata[:album_artist]
      tags.composer = metadata[:composer] if metadata[:composer]
      
      # Save changes
      unless flac.save
        @logger.error("Failed to save FLAC tags: #{file_path}")
        return false
      end
      
      @logger.info("Successfully applied FLAC tags to: #{file_path}")
      true
    rescue StandardError => e
      @logger.error("Error applying FLAC tags to #{file_path}: #{e.message}")
      false
    end
  end

  def apply_m4a_tags(file_path, metadata)
    @logger.debug("Applying tags to M4A file: #{file_path}")
    
    TagLib::MP4::File.open(file_path) do |file|
      tag = file.tag
      
      # Update basic tags
      tag.title = metadata[:title] if metadata[:title]
      tag.artist = metadata[:artist] if metadata[:artist]
      tag.album = metadata[:album] if metadata[:album]
      tag.genre = metadata[:genre] if metadata[:genre]
      tag.year = metadata[:year].to_i if metadata[:year]
      
      # Update composer and album artist
      item = TagLib::MP4::Item.from_string_list([metadata[:composer]]) if metadata[:composer]
      tag.item_list_map.insert('©wrt', item) if metadata[:composer]
      
      item = TagLib::MP4::Item.from_string_list([metadata[:album_artist]]) if metadata[:album_artist]
      tag.item_list_map.insert('aART', item) if metadata[:album_artist]
      
      file.save
    end
    
    @logger.debug("M4A tags applied successfully")
  end
end 