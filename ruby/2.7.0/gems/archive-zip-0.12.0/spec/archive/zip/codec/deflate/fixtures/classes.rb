class DeflateSpecs
  def self.compressed_data_nocomp()
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_nocomp.bin'), 'rb', &:read
    )
  end

  def self.compressed_data
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file.bin'), 'rb'
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.test_data
    File.open(File.join(File.dirname(__FILE__), 'raw_file.txt'), 'rb') do |f|
      block_given? ? yield(f) : f.read
    end
  end
end
