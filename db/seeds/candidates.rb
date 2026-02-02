# db/seeds/candidates.rb
require 'json'

puts "Loading Candidates..."

# List of candidate files
candidate_files = [
  '01_Presidentes.json',
  '02_Diputados.json',
  '03_SenadoresDistritoUnico.json',
  '04_SenadoresDistritoMultiple.json'
]

total_created = 0
total_updated = 0
total_skipped = 0

candidate_files.each do |filename|
  file_path = Rails.root.join('data', filename)

  unless File.exist?(file_path)
    puts "  ⚠️  File not found: #{filename}"
    next
  end

  puts "\n  Processing: #{filename}"

  # Read and parse JSON file
  file_content = File.read(file_path)
  data = JSON.parse(file_content)

  # The candidates data is in the 'data' key (lowercase)
  unless data['data'].is_a?(Array)
    puts "    ❌ Invalid JSON structure: 'data' key not found or not an array"
    next
  end

  candidates_data = data['data']
  puts "    Found #{candidates_data.length} candidates"

  created_count = 0
  updated_count = 0
  skipped_count = 0

  candidates_data.each_with_index do |candidate_data, index|
    begin
      # Find the political organization by its ID from the JSON
      org_code = candidate_data['idOrganizacionPolitica']&.to_s

      unless org_code.present?
        skipped_count += 1
        next
      end

      political_organization = PoliticalOrganization.find_by(code: org_code)

      unless political_organization
        # Try to create a basic organization if it doesn't exist
        political_organization = PoliticalOrganization.create(
          code: org_code,
          name: candidate_data['strOrganizacionPolitica'] || "Unknown Organization #{org_code}",
          organization_type: candidate_data['strTipoOrgPolitica']
        )
      end

      # Find or initialize candidate by document number and position
      candidate = Candidate.find_or_initialize_by(
        document_number: candidate_data['strDocumentoIdentidad'],
        position_type: candidate_data['strCargo'],
        political_organization: political_organization
      )

      # Check if it's a new record
      is_new = candidate.new_record?

      # Update attributes
      candidate.assign_attributes(
        position_number: candidate_data['intPosicion'],
        document_type: candidate_data['strTipoDocumento'],
        first_name: candidate_data['strNombres'],
        paternal_surname: candidate_data['strApellidoPaterno'],
        maternal_surname: candidate_data['strApellidoMaterno'],
        gender: candidate_data['strSexo'],
        birth_date: candidate_data['strFechaNacimiento'],
        is_native: candidate_data['strEsNativo'],
        status: candidate_data['strEstadoCandidato'],
        photo_guid: candidate_data['strGuidFoto'],
        photo_filename: candidate_data['strNombre'],
        department: candidate_data['strDepartamento'],
        province: candidate_data['strProvincia'],
        district: candidate_data['strDistrito'],
        electoral_file_code: candidate_data['strCodExpedienteExt']
      )

      # Save the record
      if candidate.save
        if is_new
          created_count += 1
          print "." if (created_count % 50).zero?
        else
          updated_count += 1
          print "u" if (updated_count % 50).zero?
        end
      else
        skipped_count += 1
        if skipped_count <= 3
          puts "\n    ⚠️  Failed to save candidate #{candidate_data['strDocumentoIdentidad']}: #{candidate.errors.full_messages.join(', ')}"
        end
      end

    rescue StandardError => e
      skipped_count += 1
      if skipped_count <= 3
        puts "\n    ❌ Error processing candidate at index #{index}: #{e.message}"
      end
    end
  end

  puts "\n    ✅ Created: #{created_count}"
  puts "    🔄 Updated: #{updated_count}" if updated_count > 0
  puts "    ⚠️  Skipped: #{skipped_count}" if skipped_count > 0

  total_created += created_count
  total_updated += updated_count
  total_skipped += skipped_count
end

puts "\n" + "="*60
puts "SUMMARY - Candidates"
puts "="*60
puts "  ✅ Total Created: #{total_created}"
puts "  🔄 Total Updated: #{total_updated}" if total_updated > 0
puts "  ⚠️  Total Skipped: #{total_skipped}" if total_skipped > 0
puts "  📊 Total in DB: #{Candidate.count}"
puts "  👥 By Position Type:"

Candidate.group(:position_type).count.each do |position, count|
  puts "     - #{position}: #{count}"
end

puts ""
