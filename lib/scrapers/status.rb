#!/usr/bin/env ruby
# lib/scrapers/status.rb - Show current status of scraped data

require_relative '../../config/environment'

puts "\n" + "="*60
puts "ELECTORAL DATA STATUS"
puts "="*60
puts ""

# Electoral Districts
puts "🏛️  ELECTORAL DISTRICTS"
puts "-"*60
districts = ElectoralDistrict.all.order(:name)
puts "Total: #{districts.count}"
puts "Expected seats: #{districts.sum(:seats_count)}"
puts ""

# Political Organizations
puts "🏢 POLITICAL ORGANIZATIONS"
puts "-"*60
puts "Total: #{PoliticalOrganization.count}"
puts "Active: #{PoliticalOrganization.active.count}"
puts ""

# Candidates Overview
puts "👥 CANDIDATES"
puts "-"*60
puts "Total: #{Candidate.count}"
puts "  Presidents: #{Candidate.presidents.count}"
puts "  Vice Presidents: #{Candidate.vice_presidents.count}"
puts "  Deputies: #{Candidate.deputies.count}"
puts "  Senators: #{Candidate.senators.count}"
puts ""

# Deputies by District
puts "📍 DEPUTIES BY ELECTORAL DISTRICT"
puts "-"*60

deputies_by_district = Candidate.deputies
                               .joins(:electoral_district)
                               .group('electoral_districts.name')
                               .count

total_with_district = deputies_by_district.values.sum
total_deputies = Candidate.deputies.count
without_district = total_deputies - total_with_district

if deputies_by_district.any?
  deputies_by_district.sort.each do |district, count|
    puts "  ✅ #{district.ljust(25)} #{count.to_s.rjust(4)} candidates"
  end
else
  puts "  ⚠️  No deputies assigned to districts yet"
end

if without_district > 0
  puts "  ⚠️  #{'Without district'.ljust(25)} #{without_district.to_s.rjust(4)} candidates"
end

puts ""
puts "Progress: #{total_with_district}/#{districts.sum(:seats_count) * 3} expected candidates"
puts "          (assuming ~3 candidates per seat on average)"
puts ""

# Coverage by District
puts "📊 DISTRICT COVERAGE"
puts "-"*60

districts_with_data = deputies_by_district.keys.count
districts_total = districts.count

puts "Districts with data: #{districts_with_data}/#{districts_total}"

if districts_with_data < districts_total
  missing = districts.pluck(:name) - deputies_by_district.keys
  puts ""
  puts "Missing districts:"
  missing.sort.each { |d| puts "  ❌ #{d}" }
end

puts ""
puts "="*60
puts ""

if districts_with_data == districts_total
  puts "🎉 ALL DISTRICTS HAVE DATA! Ready to go!"
else
  puts "⚠️  Need to scrape #{districts_total - districts_with_data} more districts"
  puts ""
  puts "Run: rails runner lib/scrapers/scrape_and_import.rb"
end

puts ""
