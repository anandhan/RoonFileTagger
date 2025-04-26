class FileScanner
  def initialize(config)
    @config = config
    @patterns = config['audio_file_patterns']
    setup_logger
    @scan_directories = load_scan_directories
  end

  def scan
    audio_files = []
    
    @logger.info("Starting directory scan")
    @logger.info("Scanning #{@scan_directories.size} directories")
    @logger.info("Using patterns: #{@patterns.join(', ')}")
    
    @scan_directories.each do |directory|
      @logger.info("Scanning directory: #{directory}")
      puts "Scanning directory: #{directory}"
      next unless File.directory?(directory)
      puts "Directory exists: #{directory}"
      
      @patterns.each do |pattern|
        @logger.debug("Searching for pattern: #{pattern}")
        puts "Searching for pattern: #{pattern}"
        Dir.glob(File.join(directory, '**', pattern)) do |file|
          if File.file?(file)
            audio_files << file
            @logger.debug("Found audio file: #{file}")
            puts "Found audio file: #{file}"
          end
        end
      end
    end
    
    @logger.info("Scan completed. Found #{audio_files.size} audio files")
    puts "Scan completed. Found #{audio_files.size} audio files"
    audio_files
  end

  private

  def setup_logger
    @logger = Logger.new(@config['logging']['file'])
    @logger.level = Logger.const_get(@config['logging']['level'])
  end

  def load_scan_directories
    directories = []
    file_path = @config['scan_directories_file']
    
    @logger.info("Loading scan directories from: #{file_path}")
    puts "Loading scan directories from: #{file_path}"
    
    return directories unless File.exist?(file_path)
    
    File.readlines(file_path).each do |line|
      line = line.strip
      puts "Processing line: '#{line}'"
      next if line.empty? || line.start_with?('#')
      directories << line
      @logger.debug("Added directory to scan: #{line}")
      puts "Added directory to scan: #{line}"
    end
    
    @logger.info("Loaded #{directories.size} directories to scan")
    puts "Loaded #{directories.size} directories to scan"
    directories
  end
end 