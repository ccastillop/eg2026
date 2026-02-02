# db/seeds/political_organizations.rb
require 'json'

puts "Loading Political Organizations..."

# Path to the JSON file
file_path = Rails.root.join('data', '00_OrganizacionPolitica.json')

# Check if file exists
unless File.exist?(file_path)
  puts "  ❌ File not found: #{file_path}"
  return
end

# Read and parse JSON file
file_content = File.read(file_path)
data = JSON.parse(file_content)

# Check if Data key exists
unless data['Data'].is_a?(Array)
  puts "  ❌ Invalid JSON structure: 'Data' key not found or not an array"
  return
end

organizations_data = data['Data']
puts "  Found #{organizations_data.length} organizations in JSON file"

created_count = 0
updated_count = 0
skipped_count = 0

organizations_data.each_with_index do |org_data, index|
  begin
    # Find or initialize by code
    organization = PoliticalOrganization.find_or_initialize_by(code: org_data['TxCodOp'])

    # Check if it's a new record
    is_new = organization.new_record?

    # Update attributes
    organization.assign_attributes(
      name: org_data['TxDesOp'],
      acronym: org_data['TxSiglasOp'],
      organization_type: org_data['TxDesTipOp'],
      status: org_data['TxDesEstOp'],
      registration_date: org_data['FeInscrpOp'],
      cancellation_date: org_data['FeCancelOp'],
      website: org_data['TxSitioWebOp'],
      address: org_data['TxDireccionOp'],
      logo_url: org_data['TxLogoOp']
    )

    # Save the record
    if organization.save
      if is_new
        created_count += 1
        print "." if (created_count % 10).zero?
      else
        updated_count += 1
        print "u" if (updated_count % 10).zero?
      end
    else
      skipped_count += 1
      puts "\n  ⚠️  Failed to save organization #{org_data['TxCodOp']}: #{organization.errors.full_messages.join(', ')}"
    end

  rescue StandardError => e
    skipped_count += 1
    puts "\n  ❌ Error processing organization at index #{index}: #{e.message}"
  end
end

puts "\n"
puts "  ✅ Created: #{created_count} organizations"
puts "  🔄 Updated: #{updated_count} organizations" if updated_count > 0
puts "  ⚠️  Skipped: #{skipped_count} organizations" if skipped_count > 0
puts "  📊 Total in DB: #{PoliticalOrganization.count}"
puts ""
