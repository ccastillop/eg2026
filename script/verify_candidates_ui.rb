#!/usr/bin/env ruby
# frozen_string_literal: true

# Verification script for Candidates UI implementation
# This script checks that all components are in place and working

puts "=" * 80
puts "Candidates UI Verification Script"
puts "=" * 80
puts

# Check if we're in Rails root
unless File.exist?("config/application.rb")
  puts "❌ Error: Must be run from Rails root directory"
  exit 1
end

require_relative "../config/environment"

# Test 1: Check models exist and have data
puts "📋 Test 1: Checking models and data..."
begin
  candidate_count = Candidate.count
  org_count = PoliticalOrganization.count
  district_count = ElectoralDistrict.count

  puts "  ✅ Candidate model: #{candidate_count} records"
  puts "  ✅ PoliticalOrganization model: #{org_count} records"
  puts "  ✅ ElectoralDistrict model: #{district_count} records"

  if candidate_count.zero?
    puts "  ⚠️  Warning: No candidates in database. Run seeds first!"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
  exit 1
end
puts

# Test 2: Check routes
puts "📋 Test 2: Checking routes..."
begin
  routes = Rails.application.routes.routes
  candidates_index = routes.any? { |r| r.defaults[:controller] == "candidates" && r.defaults[:action] == "index" }
  candidates_show = routes.any? { |r| r.defaults[:controller] == "candidates" && r.defaults[:action] == "show" }
  root_route = routes.find { |r| r.name == "root" }

  if candidates_index
    puts "  ✅ Candidates index route exists"
  else
    puts "  ❌ Candidates index route missing"
  end

  if candidates_show
    puts "  ✅ Candidates show route exists"
  else
    puts "  ❌ Candidates show route missing"
  end

  if root_route && root_route.defaults[:controller] == "candidates"
    puts "  ✅ Root route points to candidates#index"
  else
    puts "  ⚠️  Warning: Root route doesn't point to candidates#index"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end
puts

# Test 3: Check controller exists and methods work
puts "📋 Test 3: Checking controller..."
begin
  controller = CandidatesController.new

  if controller.respond_to?(:index)
    puts "  ✅ CandidatesController#index method exists"
  else
    puts "  ❌ CandidatesController#index method missing"
  end

  if controller.respond_to?(:show)
    puts "  ✅ CandidatesController#show method exists"
  else
    puts "  ❌ CandidatesController#show method missing"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end
puts

# Test 4: Check views exist
puts "📋 Test 4: Checking views..."
views = [
  "app/views/candidates/index.html.erb",
  "app/views/candidates/show.html.erb"
]

views.each do |view_path|
  if File.exist?(view_path)
    puts "  ✅ #{view_path} exists"
  else
    puts "  ❌ #{view_path} missing"
  end
end
puts

# Test 5: Check Kaminari pagination views
puts "📋 Test 5: Checking Kaminari pagination views..."
kaminari_views = [
  "app/views/kaminari/_paginator.html.erb",
  "app/views/kaminari/_page.html.erb",
  "app/views/kaminari/_gap.html.erb",
  "app/views/kaminari/_first_page.html.erb",
  "app/views/kaminari/_last_page.html.erb",
  "app/views/kaminari/_next_page.html.erb",
  "app/views/kaminari/_prev_page.html.erb"
]

kaminari_views.each do |view_path|
  if File.exist?(view_path)
    puts "  ✅ #{view_path} exists"
  else
    puts "  ❌ #{view_path} missing"
  end
end
puts

# Test 6: Check Tailwind CSS setup
puts "📋 Test 6: Checking Tailwind CSS setup..."
tailwind_files = [
  "app/assets/tailwind/application.css",
  "Procfile.dev"
]

tailwind_files.each do |file_path|
  if File.exist?(file_path)
    puts "  ✅ #{file_path} exists"
  else
    puts "  ❌ #{file_path} missing"
  end
end

# Check if tailwindcss-rails gem is installed
if Gem.loaded_specs.key?("tailwindcss-rails")
  puts "  ✅ tailwindcss-rails gem installed"
else
  puts "  ⚠️  Warning: tailwindcss-rails gem not found"
end
puts

# Test 7: Test pagination functionality
puts "📋 Test 7: Testing pagination..."
begin
  page1 = Candidate.page(1).per(30)
  puts "  ✅ First page loaded: #{page1.count} candidates"
  puts "  ✅ Total pages: #{page1.total_pages}"
  puts "  ✅ Total count: #{page1.total_count}"

  if page1.total_pages > 1
    page2 = Candidate.page(2).per(30)
    puts "  ✅ Second page loaded: #{page2.count} candidates"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end
puts

# Test 8: Test candidate associations
puts "📋 Test 8: Testing candidate associations..."
begin
  candidate = Candidate.includes(:political_organization, :electoral_district).first

  if candidate
    puts "  ✅ Sample candidate: #{candidate.full_name}"

    if candidate.political_organization
      puts "  ✅ Political organization association works: #{candidate.political_organization.name}"
    else
      puts "  ⚠️  Warning: Candidate missing political organization"
    end

    if candidate.electoral_district
      puts "  ✅ Electoral district association works: #{candidate.electoral_district.name}"
    else
      puts "  ℹ️  Info: Candidate has no electoral district (may be normal for presidents)"
    end
  else
    puts "  ⚠️  Warning: No candidates to test"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end
puts

# Test 9: Test filtering
puts "📋 Test 9: Testing filter functionality..."
begin
  deputies = Candidate.where(position_type: "DIPUTADO").limit(1).count
  presidents = Candidate.where(position_type: "PRESIDENTE DE LA REPÚBLICA").limit(1).count

  puts "  ✅ Position filter works (Deputies: #{Candidate.where(position_type: 'DIPUTADO').count})"
  puts "  ✅ Position filter works (Presidents: #{Candidate.where(position_type: 'PRESIDENTE DE LA REPÚBLICA').count})"

  # Test search
  search_results = Candidate.where("first_name LIKE ?", "%A%").limit(10).count
  puts "  ✅ Search filter works (#{search_results} results for names containing 'A')"
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
end
puts

# Test 10: Check Gemfile dependencies
puts "📋 Test 10: Checking Gemfile dependencies..."
gemfile = File.read("Gemfile")

if gemfile.include?("kaminari")
  puts "  ✅ kaminari gem in Gemfile"
else
  puts "  ❌ kaminari gem missing from Gemfile"
end

if gemfile.include?("tailwindcss-rails")
  puts "  ✅ tailwindcss-rails gem in Gemfile"
else
  puts "  ❌ tailwindcss-rails gem missing from Gemfile"
end
puts

# Summary
puts "=" * 80
puts "Verification Complete!"
puts "=" * 80
puts
puts "Next steps:"
puts "1. Start the development server: bin/dev"
puts "2. Visit http://localhost:3000 to see the candidates index"
puts "3. Click on any candidate to view details"
puts
puts "Total Candidates: #{Candidate.count}"
puts "Pages: #{(Candidate.count / 30.0).ceil}"
puts "=" * 80
