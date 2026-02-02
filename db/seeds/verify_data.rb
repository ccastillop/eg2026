# db/seeds/verify_data.rb
puts "\n" + "="*60
puts "DATA VERIFICATION - Elecciones Generales 2026"
puts "="*60
puts "\n"

# Verify Political Organizations
puts "📊 POLITICAL ORGANIZATIONS"
puts "-" * 60
puts "  Total: #{PoliticalOrganization.count}"
puts "  Active: #{PoliticalOrganization.active.count}"
puts "  Political Parties: #{PoliticalOrganization.political_parties.count}"
puts "  Alliances: #{PoliticalOrganization.alliances.count}"
puts ""

# Show top organizations by candidate count
puts "  Top 5 Organizations by Candidate Count:"
PoliticalOrganization.joins(:candidates)
  .group('political_organizations.id')
  .order('COUNT(candidates.id) DESC')
  .limit(5)
  .each do |org|
    puts "    • #{org.display_name}: #{org.candidates.count} candidates"
  end
puts ""

# Verify Candidates
puts "👥 CANDIDATES"
puts "-" * 60
puts "  Total: #{Candidate.count}"
puts "  Active: #{Candidate.active.count}"
puts ""

puts "  By Position Type:"
puts "    • Presidents: #{Candidate.presidents.count}"
puts "    • First Vice Presidents: #{Candidate.where(position_type: 'PRIMER VICEPRESIDENTE DE LA REPÚBLICA').count}"
puts "    • Second Vice Presidents: #{Candidate.where(position_type: 'SEGUNDO VICEPRESIDENTE DE LA REPÚBLICA').count}"
puts "    • Deputies: #{Candidate.deputies.count}"
puts "    • Senators: #{Candidate.senators.count}"
puts ""

puts "  By Status:"
Candidate.group(:status).count.sort_by { |_, count| -count }.each do |status, count|
  puts "    • #{status}: #{count}"
end
puts ""

puts "  By Gender:"
Candidate.where.not(gender: [nil, '']).group(:gender).count.each do |gender, count|
  puts "    • #{gender}: #{count}"
end
puts ""

# Verify Data Integrity
puts "🔍 DATA INTEGRITY CHECKS"
puts "-" * 60

# Check for candidates without organizations
orphaned = Candidate.where(political_organization_id: nil).count
if orphaned > 0
  puts "  ⚠️  WARNING: #{orphaned} candidates without political organization"
else
  puts "  ✅ All candidates have a political organization"
end

# Check for candidates without document numbers
no_doc = Candidate.where(document_number: [nil, '']).count
if no_doc > 0
  puts "  ⚠️  WARNING: #{no_doc} candidates without document number"
else
  puts "  ✅ All candidates have document numbers"
end

# Check for duplicate candidates
duplicates = Candidate.group(:document_number, :position_type)
  .having('COUNT(*) > 1')
  .count
if duplicates.any?
  puts "  ⚠️  WARNING: #{duplicates.count} potential duplicate candidates"
else
  puts "  ✅ No duplicate candidates found"
end

# Check for organizations without candidates
empty_orgs = PoliticalOrganization.left_joins(:candidates)
  .group('political_organizations.id')
  .having('COUNT(candidates.id) = 0')
  .count
if empty_orgs.any?
  puts "  ⚠️  INFO: #{empty_orgs.count} organizations without candidates"
else
  puts "  ✅ All organizations have at least one candidate"
end

puts ""

# Geographic Distribution
puts "🗺️  GEOGRAPHIC DISTRIBUTION"
puts "-" * 60
departments = Candidate.where.not(department: [nil, '']).group(:department).count.sort_by { |_, count| -count }
puts "  Candidates by Department (Top 10):"
departments.first(10).each do |dept, count|
  puts "    • #{dept}: #{count}"
end

puts ""
puts "="*60
puts "VERIFICATION COMPLETED!"
puts "="*60
puts "\n"
