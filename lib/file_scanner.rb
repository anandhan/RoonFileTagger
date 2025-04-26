class FileScanner
  def initialize(config)
    @config = config
    @patterns = config['audio_file_patterns']
    @scan_directories = load_scan_directories
  end

  def scan
    audio_files = []
    
    @scan_directories.each do |directory|
      next unless File.directory?(directory)
      
      @patterns.each do |pattern|
        Dir.glob(File.join(directory, '**', pattern)) do |file|
          audio_files << file if File.file?(file)
        end
      end
    end
    
    audio_files
  end

  private

  def load_scan_directories
    directories = []
    file_path = @config['scan_directories_file']
    
    return directories unless File.exist?(file_path)
    
    File.readlines(file_path).each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      directories << line
    end
    
    directories
  end
end 