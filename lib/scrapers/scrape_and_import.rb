#!/usr/bin/env ruby
# lib/scrapers/scrape_and_import.rb
#
# Combined script to scrape all deputies data from JNE and import to database
#
# Usage:
#   rails runner lib/scrapers/scrape_and_import.rb
#
# Options:
#   DISTRICTS=LIMA,AREQUIPA rails runner lib/scrapers/scrape_and_import.rb  # Specific districts
#   SKIP_BACKUP=true rails runner lib/scrapers/scrape_and_import.rb         # Skip database backup

require_relative 'jne_deputies_scraper'
require_relative 'import_scraped_deputies'

puts "\n" + "="*60
puts "JNE DEPUTIES - SCRAPE AND IMPORT (ALL-IN-ONE)"
puts "="*60
puts "Started at: #{Time.now}"
puts ""

# Parse options
districts_filter = ENV['DISTRICTS']&.split(',')&.map(&:strip)
skip_backup = ENV['SKIP_BACKUP'] == 'true'

# PHASE 1: Database Backup (optional but recommended)
unless skip_backup
  puts "📦 PHASE 1: Creating database backup..."
  puts "-"*60

  begin
    backup_dir = Rails.root.join('tmp', 'backups')
    Dir.mkdir(backup_dir) unless Dir.exist?(backup_dir)

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    backup_file = backup_dir.join("database_before_import_#{timestamp}.sqlite3")

    if File.exist?(Rails.root.join('db', 'development.sqlite3'))
      FileUtils.cp(
        Rails.root.join('db', 'development.sqlite3'),
        backup_file
      )
      puts "✅ Backup created: #{backup_file}"
    else
      puts "⚠️  Database file not found, skipping backup"
    end
  rescue StandardError => e
    puts "⚠️  Backup failed: #{e.message}"
    puts "Continuing anyway..."
  end

  puts ""
end

# PHASE 2: Scraping
puts "🔍 PHASE 2: Scraping data from JNE..."
puts "-"*60
puts ""

scraper = Scrapers::JneDeputiesScraper.new

if districts_filter
  puts "🎯 Scraping specific districts: #{districts_filter.join(', ')}"
  puts ""

  districts_filter.each_with_index do |district_code, index|
    district = ElectoralDistrict.find_by(code: district_code.upcase)

    if district
      scraper.scrape_district(district, index + 1, districts_filter.length)
    else
      puts "⚠️  District not found: #{district_code}"
    end

    sleep 2 # Be nice to the server
  end
else
  puts "🌐 Scraping ALL districts (27 total)"
  puts "Estimated time: 2-3 minutes"
  puts ""

  scraper.scrape_all_deputies
end

# Save to temporary JSON
puts "\n💾 Saving scraped data to JSON..."
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
json_file = Rails.root.join('tmp', "scraped_deputies_#{timestamp}.json")
scraper.save_to_json(json_file)

# PHASE 3: Importing
puts "\n" + "="*60
puts "📥 PHASE 3: Importing data to database..."
puts "-"*60
puts ""

importer = ImportScrapedDeputies.new(json_file)
success = importer.import

# PHASE 4: Verification
if success
  puts "\n" + "="*60
  puts "🎉 ALL COMPLETE!"
  puts "="*60
  puts ""

  # Show statistics
  puts "📊 Final Database Statistics:"
  puts "  Total Candidates: #{Candidate.count}"
  puts "  Total Deputies: #{Candidate.deputies.count}"
  puts ""
  puts "  Deputies by District:"

  stats = Candidate.deputies
                   .joins(:electoral_district)
                   .group('electoral_districts.name')
                   .count
                   .sort_by { |_, count| -count }

  stats.each do |district, count|
    puts "    • #{district}: #{count}"
  end

  no_district = Candidate.deputies.where(electoral_district_id: nil).count
  if no_district > 0
    puts "    • Without district: #{no_district}"
  end

  puts ""
  puts "📁 Scraped JSON saved at: #{json_file}"
  puts "📦 Database backup at: tmp/backups/" unless skip_backup
  puts ""
  puts "✅ Everything is ready!"
  puts ""
else
  puts "\n" + "="*60
  puts "⚠️  IMPORT COMPLETED WITH ISSUES"
  puts "="*60
  puts ""
  puts "Some records may have failed to import."
  puts "Check the import summary above for details."
  puts ""
  puts "📁 Scraped JSON saved at: #{json_file}"
  puts "You can try importing again with:"
  puts "  rails runner lib/scrapers/import_scraped_deputies.rb #{json_file}"
  puts ""
end

puts "Finished at: #{Time.now}"
puts ""

# Exit with appropriate code
exit(success ? 0 : 1)
