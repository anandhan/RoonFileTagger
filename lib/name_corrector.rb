class NameCorrector
  def initialize(correction_file_path)
    @correction_file_path = correction_file_path
    @corrections = load_corrections
  end

  def correct_names(metadata)
    corrected = metadata.dup
    
    # Correct artist name
    if metadata[:artist]
      corrected[:artist] = find_correction(metadata[:artist])
    end
    
    # Correct composer name
    if metadata[:composer]
      corrected[:composer] = find_correction(metadata[:composer])
    end
    
    corrected
  end

  private

  def load_corrections
    corrections = {}
    
    return corrections unless File.exist?(@correction_file_path)
    
    File.readlines(@correction_file_path).each do |line|
      next if line.strip.empty? || line.start_with?('#')
      
      incorrect, correct = line.strip.split('|').map(&:strip)
      corrections[incorrect.downcase] = correct if incorrect && correct
    end
    
    corrections
  end

  def find_correction(name)
    # Try exact match first
    return @corrections[name.downcase] if @corrections.key?(name.downcase)
    
    # Try fuzzy matching
    @corrections.each do |incorrect, correct|
      # Simple similarity check - you might want to use a more sophisticated algorithm
      if name.downcase.include?(incorrect) || incorrect.include?(name.downcase)
        return correct
      end
    end
    
    # Return original if no correction found
    name
  end
end 