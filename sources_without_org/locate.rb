require 'rubygems'
require 'datacatalog'

class Analyzer
  def initialize
    @config = YAML.load_file("config.yml")
    DataCatalog.base_uri = @config['base_uri']
    DataCatalog.api_key  = @config['api_key']
  end

  def locate
    puts "Fetching sources from API..."
    @sources = DataCatalog::Source.all

    puts "Finding sources without associated organizations..."
    @sources_without_org = @sources.select do |source|
      source.organization.blank?
    end
  end
  
  def show_summary
    puts "\nSummary:"
    Utility.summarize(@sources, @sources, "sources")
    Utility.summarize(@sources_without_org, @sources, "sources without associated organization")
  end
  
  def show_details
    puts "\nDetails:"
    @sources_without_org.each do |source|
      puts "  - #{source.title}"
      puts "    #{source.url}"
    end
  end
end

class Utility
  def self.summarize(count, total, text)
    puts "  %*i (%5.1f %%) %s" %
      [total.length.to_s.length, count.length, count.length * 100.0 / total.length, text]
  end
end

a = Analyzer.new
a.locate
a.show_summary
a.show_details
