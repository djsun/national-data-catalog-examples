require 'rubygems'
require 'datacatalog'

LIMIT = {
  :human => "100 MB",
  :bytes => 100 * 1024 * 1024
}

def setup
  config = YAML.load_file("config.yml")
  DataCatalog.base_uri = config['base_uri']
  DataCatalog.api_key = config['api_key']
end

def calculate(verbose=false)
  puts "Fetching downloads from API..."
  downloads = DataCatalog::Download.all

  puts "Analyzing downloads..."
  csv_downloads = downloads.select do |download|
    download.format == "csv"
  end
  
  small_csv_downloads = csv_downloads.select do |download|
    bytes = download['size']['bytes']
    bytes && bytes < LIMIT[:bytes]
  end

  puts "\nSummary:"
  summarize(downloads, downloads, "downloads")
  summarize(csv_downloads, downloads, "CSV downloads")
  summarize(small_csv_downloads, downloads, "CSV downloads < #{LIMIT[:human]}")
end

def summarize(count, total, text)
  puts "  %*i (%5.1f %%) %s" %
    [total.length.to_s.length, count.length, count.length * 100.0 / total.length, text]
end

setup
calculate(true)
