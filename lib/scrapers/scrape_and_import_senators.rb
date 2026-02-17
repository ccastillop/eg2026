#!/usr/bin/env ruby
# lib/scrapers/scrape_and_import_senators.rb
#
# Combined script to scrape all senators data from JNE and import to database
#
# Usage:
#   rails runner lib/scrapers/scrape_and_import_senators.rb
#
# Options:
#   SKIP_BACKUP=true rails runner lib/scrapers/scrape_and_import_senators.rb         # Skip database backup
#
# Note: The JNE API returns all senators in a single call (not filtered by district)
#       so there's no need for per-district filtering

require_relative 'jne_senators_scraper'
require_relative 'import_scraped_senators'

puts "\n" + "="*60
puts "JNE SENATORS - SCRAPE AND IMPORT (ALL-IN-ONE)"
puts "="*60
puts "Started at: #{Time.now}"
puts ""

# Parse options
skip_backup = ENV['SKIP_BACKUP'] == 'true'

# PHASE 1: Database Backup (optional but recommended)
unless skip_backup
  puts "📦 PHASE 1: Creating database backup..."
  puts "-"*60

  begin
    backup_dir = Rails.root.join('tmp', 'backups')
    Dir.mkdir(backup_dir) unless Dir.exist?(backup_dir)

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    backup_file = backup_dir.join("database_before_senators_#{timestamp}.sqlite3")

    db_file = Rails.root.join('storage', 'development.sqlite3')
    if File.exist?(db_file)
      FileUtils.cp(db_file, backup_file)
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

scraper = Scrapers::JneSenatorsScaper.new

puts "🌐 Scraping ALL senators (optimized - 2 API calls total)"
puts "   - Single District (Distrito Único): 1 call"
puts "   - Multiple District (national list): 1 call"
puts "Estimated time: ~10 seconds"
puts ""

scraper.scrape_all_senators

# Save to temporary JSON
puts "\n💾 Saving scraped data to JSON..."
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
json_file = Rails.root.join('tmp', "scraped_senators_#{timestamp}.json")
scraper.save_to_json(json_file)

# PHASE 3: Importing
puts "\n" + "="*60
puts "📥 PHASE 3: Importing data to database..."
puts "-"*60
puts ""

importer = ImportScrapedSenators.new(json_file)
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
  puts "  Total Senators: #{Candidate.where(position_type: 'SENADOR').count}"
  puts ""

  senators_with_district = Candidate.where(position_type: 'SENADOR')
                                   .where.not(electoral_district_id: nil)
                                   .count
  senators_without_district = Candidate.where(position_type: 'SENADOR')
                                      .where(electoral_district_id: nil)
                                      .count

  puts "  Senators with electoral district: #{senators_with_district}"
  puts "  Senators without electoral district: #{senators_without_district}"
  puts ""
  puts "  Senators by District:"

  stats = Candidate.where(position_type: 'SENADOR')
                   .joins(:electoral_district)
                   .group('electoral_districts.name')
                   .count
                   .sort_by { |_, count| -count }

  stats.each do |district, count|
    puts "    • #{district}: #{count}"
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
  puts "  rails runner lib/scrapers/import_scraped_senators.rb #{json_file}"
  puts ""
end

puts "Finished at: #{Time.now}"
puts ""

# Exit with appropriate code
exit(success ? 0 : 1)
