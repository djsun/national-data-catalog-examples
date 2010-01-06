require 'rubygems'
require 'datacatalog'

THRESHOLD = 100 * 1024 * 1024 # 100 MB

def setup
  config = YAML.load_file("config.yml")
  DataCatalog.base_uri = config['base_uri']
  DataCatalog.api_key = config['api_key']
end

def calculate(verbose=false)
  puts "Fetching sources from API..."
  downloads = DataCatalog::Download.all

  puts "Selecting downloads with size < #{THRESHOLD}..."
  matches = downloads.select do |download|
    if download.format == "xml"
      bytes = download['size']['bytes']
      bytes && bytes < THRESHOLD
    end
  end

  puts "\nFound #{matches.length} downloads"

  if verbose
    puts "\n%-24s %-10s %s" % ["source_id", "bytes", "label"]
    matches.each do |match|
      puts "%-24s %10i %4i %s" % [match.source_id, match['size']['bytes'],
        match['size'].number, match['size'].unit]
    end
  end
end

setup
calculate(true)
