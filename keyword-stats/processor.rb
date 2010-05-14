require 'rubygems'
require 'mongo'
require 'yaml'

class Processor
  
  def initialize
    @connection = Mongo::Connection.new.db("natdatcat_dev")
    @sources = @connection.collection("sources")
    @keywords_filename = "keywords.yml"
    @hits_filename = "hits.yml"
  end

  def run(options={})
    catalog_names = @sources.distinct(:catalog_name)
    puts "Found #{catalog_names.length} catalogs"

    if options[:regenerate_keywords]
      keywords = generate_keywords
      puts "Saving hits to #{@keywords_filename}"
      save_yaml(@keywords_filename, keywords)
    end

    keywords = YAML::load_file(@keywords_filename)
    puts "Found #{keywords.length} keywords"

    threshold = options[:pruning_threshold] || 100
    pruned_keywords = keywords.select { |k, v| v >= threshold }
    puts "Pruned to #{pruned_keywords.length} keywords"

    sorted_keywords = pruned_keywords.sort_by { |k, v| -v }
    hits = keyword_hits(sorted_keywords, catalog_names)

    sorted_hits = hits.sort_by { |k, v| [-v[0], -v[1]] }
    
    puts "Saving sorted_hits to #{@hits_filename}"
    save_yaml(@hits_filename, sorted_hits)
    
    sorted_hits.each do |element|
      keyword       = element[0]
      catalog_count = element[1][0]
      overall_count = element[1][1]
      puts "%20s %i %i" %
        [keyword, catalog_count, overall_count]
    end
    
    true
  end
  
  protected

  def generate_keywords
    puts "Generating keywords"
    sources = @sources.find
    keywords = {}
    sources.each do |source|
      source['_keywords'].each do |keyword|
        keywords[keyword] ||= 0
        keywords[keyword] += 1
      end
    end
    keywords
  end

  # In how many catalogs does this keyword occur?
  #
  # Return value will be in this range:
  # * minimum : 0
  # * maximum : catalog_names.length
  def keyword_catalog_count(keyword, catalog_names)
    catalog_names.reduce(0) do |hits, catalog_name|
      matches = @sources.find({
        :_keywords    => keyword,
        :catalog_name => catalog_name,
      })
      hits + ((matches.count > 0) ? 1 : 0)
    end
  end

  def keyword_hits(keywords_and_counts, catalog_names)
    h = {}
    keywords_and_counts.each do |keyword, count|
      h[keyword] = [
        keyword_catalog_count(keyword, catalog_names),
        count
      ]
    end
    h
  end
  
  def save_yaml(filename, data)
    File.open(filename, "w") do |f|
      YAML::dump(data, f)
    end
  end
  
end

processor = Processor.new
processor.run({
  :pruning_threshold => 5
})
