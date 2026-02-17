#!/usr/bin/env ruby
# lib/scrapers/import_scraped_senators.rb
#
# Import scraped senators data into the database
#
# Usage:
#   rails runner lib/scrapers/import_scraped_senators.rb path/to/scraped_senators.json

class ImportScrapedSenators
  def initialize(json_file_path)
    @json_file_path = json_file_path
    @stats = {
      total_processed: 0,
      created: 0,
      updated: 0,
      skipped: 0,
      errors: 0
    }
  end

  def import
    puts "\n" + "="*60
    puts "IMPORTING SCRAPED SENATORS DATA"
    puts "="*60
    puts "File: #{@json_file_path}"
    puts ""

    unless File.exist?(@json_file_path)
      puts "❌ File not found: #{@json_file_path}"
      return false
    end

    # Read and parse JSON
    puts "📖 Reading JSON file..."
    file_content = File.read(@json_file_path)
    data = JSON.parse(file_content)

    puts "✅ JSON loaded successfully"
    puts "📊 Metadata:"
    puts "  - Scraped at: #{data['scraped_at']}"
    puts "  - Total batches: #{data['total_batches']}"
    puts "  - Total candidates: #{data['total_candidates']}"
    puts ""

    # Process results
    results = data['results']
    puts "🏛️  Processing #{results.length} batches..."
    puts ""

    results.each_with_index do |batch, index|
      process_batch(batch, index + 1, results.length)
    end

    # Print summary
    print_summary

    # Return success status
    @stats[:errors].zero?
  end

  private

  def process_batch(batch, current, total)
    election_type = batch['election_type']
    candidates_data = batch['candidates'] || []

    if election_type == 'SENADORES_DISTRITO_UNICO'
      puts "📍 [#{current}/#{total}] Single District - Distrito Único (#{candidates_data.length} candidates)"
    elsif election_type == 'SENADORES_DISTRITO_MULTIPLE'
      puts "📍 [#{current}/#{total}] Multiple District - National List (#{candidates_data.length} candidates)"
    end

    # Import candidates (electoral district will be determined from candidate data)
    candidates_data.each_with_index do |candidate_data, idx|
      import_candidate(candidate_data, nil)

      # Progress indicator
      print "." if (idx + 1) % 50 == 0
    end

    puts "\n   ✅ Completed"
    puts ""
  end

  def import_candidate(candidate_data, electoral_district = nil)
    @stats[:total_processed] += 1

    begin
      # Find the political organization
      org_id = candidate_data['idOrganizacionPolitica']&.to_s

      unless org_id.present?
        @stats[:skipped] += 1
        return
      end

      political_organization = PoliticalOrganization.find_by(code: org_id)

      unless political_organization
        # Create organization if it doesn't exist
        political_organization = PoliticalOrganization.create!(
          code: org_id,
          name: candidate_data['strOrganizacionPolitica'] || "Unknown Organization #{org_id}",
          organization_type: candidate_data['strTipoOrgPolitica']
        )
      end

      # Find or initialize candidate
      candidate = Candidate.find_or_initialize_by(
        document_number: candidate_data['strDocumentoIdentidad'],
        position_type: 'SENADOR',
        political_organization: political_organization
      )

      is_new = candidate.new_record?

      # Map department to electoral district if not already set
      if electoral_district.nil? && candidate_data['strDepartamento'].present?
        # Try to find district by department name
        dept_name = candidate_data['strDepartamento'].strip.upcase

        # Normalize department names
        dept_mapping = {
          'ANCASH' => 'ÁNCASH',
          'APURIMAC' => 'APURÍMAC',
          'HUANUCO' => 'HUÁNUCO',
          'JUNIN' => 'JUNÍN',
          'SAN_MARTIN' => 'SAN MARTÍN',
          'MADRE_DE_DIOS' => 'MADRE DE DIOS',
          'LA_LIBERTAD' => 'LA LIBERTAD'
        }

        normalized_dept = dept_mapping[dept_name] || dept_name.titleize
        electoral_district = ElectoralDistrict.find_by('UPPER(name) = ?', normalized_dept.upcase)
      end

      # Update candidate attributes
      candidate.assign_attributes(
        electoral_district: electoral_district,
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

      # Save
      if candidate.save
        if is_new
          @stats[:created] += 1
        else
          @stats[:updated] += 1
        end
      else
        @stats[:errors] += 1
        if @stats[:errors] <= 5
          puts "\n   ⚠️  Failed to save: #{candidate.errors.full_messages.join(', ')}"
        end
      end

    rescue StandardError => e
      @stats[:errors] += 1
      if @stats[:errors] <= 5
        puts "\n   ❌ Error importing candidate: #{e.message}"
      end
    end
  end

  def print_summary
    puts ""
    puts "="*60
    puts "IMPORT SUMMARY"
    puts "="*60
    puts "✅ Total processed: #{@stats[:total_processed]}"
    puts "➕ Created: #{@stats[:created]}"
    puts "🔄 Updated: #{@stats[:updated]}"
    puts "⏭️  Skipped: #{@stats[:skipped]}"
    puts "❌ Errors: #{@stats[:errors]}"
    puts ""

    # Database statistics
    puts "📊 Database Status:"
    puts "  - Total candidates: #{Candidate.count}"
    puts "  - Senators: #{Candidate.where(position_type: 'SENADOR').count}"
    puts "  - Senators with district: #{Candidate.where(position_type: 'SENADOR').where.not(electoral_district_id: nil).count}"
    puts ""

    # Senators by district
    senators_by_district = Candidate.where(position_type: 'SENADOR')
                                   .joins(:electoral_district)
                                   .group('electoral_districts.name')
                                   .count
                                   .sort_by { |_, count| -count }

    if senators_by_district.any?
      puts "  - Senators by district:"
      senators_by_district.first(10).each do |district, count|
        puts "    • #{district}: #{count}"
      end
    end

    puts "="*60
    puts ""
  end
end

# Allow running as a standalone script
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: rails runner lib/scrapers/import_scraped_senators.rb path/to/scraped_senators.json"
    exit 1
  end

  importer = ImportScrapedSenators.new(ARGV[0])
  success = importer.import
  exit(success ? 0 : 1)
end
