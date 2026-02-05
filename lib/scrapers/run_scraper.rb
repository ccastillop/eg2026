#!/usr/bin/env ruby
# lib/scrapers/run_scraper.rb
#
# Main script to scrape all deputies data from JNE
#
# Usage:
#   rails runner lib/scrapers/run_scraper.rb
#
# Options:
#   DISTRICTS=LIMA,AREQUIPA rails runner lib/scrapers/run_scraper.rb  # Specific districts
#   SKIP_SAVE=true rails runner lib/scrapers/run_scraper.rb           # Don't save JSON
#   OUTPUT=custom_name.json rails runner lib/scrapers/run_scraper.rb  # Custom filename

require_relative 'jne_deputies_scraper'

puts "\n" + "="*60
puts "JNE DEPUTIES SCRAPER - Main Runner"
puts "="*60
puts "Started at: #{Time.now}"
puts ""

# Parse options from environment variables
districts_filter = ENV['DISTRICTS']&.split(',')&.map(&:strip)
skip_save = ENV['SKIP_SAVE'] == 'true'
output_file = ENV['OUTPUT']

# Create scraper instance
scraper = Scrapers::JneDeputiesScraper.new

# Display configuration
if districts_filter
  puts "🎯 Mode: Scraping specific districts"
  puts "Districts: #{districts_filter.join(', ')}"
  puts ""

  districts_filter.each do |district_code|
    district = ElectoralDistrict.find_by(code: district_code.upcase)

    if district
      scraper.scrape_district(district)
    else
      puts "⚠️  District not found: #{district_code}"
    end

    sleep 2 # Be nice to the server
  end
else
  puts "🌐 Mode: Scraping ALL districts"
  puts "This will take approximately 2-3 minutes..."
  puts ""

  # Scrape all districts
  scraper.scrape_all_deputies
end

# Save results
unless skip_save
  puts "\n💾 Saving results to JSON..."

  json_file = if output_file
    Rails.root.join('data', output_file)
  else
    nil # Will use default filename with timestamp
  end

  saved_file = scraper.save_to_json(json_file)

  puts "\n" + "="*60
  puts "SCRAPING COMPLETED!"
  puts "="*60
  puts ""
  puts "📁 Data saved to: #{saved_file}"
  puts ""
  puts "Next steps:"
  puts "1. Verify the JSON file looks correct"
  puts "2. Import to database:"
  puts "   rails runner lib/scrapers/import_scraped_deputies.rb #{saved_file}"
  puts ""
  puts "Or use the combined script:"
  puts "   rails runner lib/scrapers/scrape_and_import.rb"
  puts ""
else
  puts "\n⚠️  Skipped saving to JSON (SKIP_SAVE=true)"
end

puts "Finished at: #{Time.now}"
puts ""
