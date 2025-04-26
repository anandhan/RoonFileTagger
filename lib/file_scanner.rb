class FileScanner
  def initialize(config)
    @config = config
    @patterns = config['audio_file_patterns']
  end

  def scan
    audio_files = []
    
    @config['scan_directories'].each do |directory|
      next unless File.directory?(directory)
      
      @patterns.each do |pattern|
        Dir.glob(File.join(directory, '**', pattern)) do |file|
          audio_files << file if File.file?(file)
        end
      end
    end
    
    audio_files
  end
end 