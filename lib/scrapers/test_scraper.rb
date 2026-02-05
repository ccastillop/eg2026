#!/usr/bin/env ruby
# lib/scrapers/test_scraper.rb
#
# Quick test script to verify the JNE scraper works with real data
#
# Usage:
#   ruby lib/scrapers/test_scraper.rb [DISTRICT_CODE]
#
# Example:
#   ruby lib/scrapers/test_scraper.rb LIMA
#   ruby lib/scrapers/test_scraper.rb AREQUIPA

require_relative '../../config/environment'
require_relative 'jne_deputies_scraper'

puts "\n🧪 JNE Deputies Scraper - Test Script"
puts "="*60

# Get district code from command line or use default
district_code = ARGV[0] || 'LIMA'

puts "Testing with district: #{district_code}"
puts ""

# Create scraper instance
scraper = Scrapers::JneDeputiesScraper.new

# Test the district
result = scraper.test_single_district(district_code)

if result && result[:candidates].any?
  puts "\n" + "="*60
  puts "SUCCESS! ✅"
  puts "="*60
  puts ""
  puts "The scraper is working correctly!"
  puts ""
  puts "Next steps:"
  puts "1. Run for all districts:"
  puts "   rails runner lib/scrapers/run_scraper.rb"
  puts ""
  puts "2. Or scrape and import in one command:"
  puts "   rails runner lib/scrapers/scrape_and_import.rb"
  puts ""
else
  puts "\n" + "="*60
  puts "FAILED ❌"
  puts "="*60
  puts ""
  puts "The scraper didn't return data. Possible issues:"
  puts "- Authentication token expired"
  puts "- District code invalid"
  puts "- API endpoint changed"
  puts "- Network issues"
  puts ""
  puts "Check the error messages above for details."
  puts ""
end
