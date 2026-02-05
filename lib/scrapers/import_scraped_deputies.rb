# lib/scrapers/import_scraped_deputies.rb
#
# Script to import scraped deputies data into the database
#
# Usage:
#   rails runner lib/scrapers/import_scraped_deputies.rb path/to/scraped_data.json

require 'json'

class ImportScrapedDeputies
  attr_reader :stats

  def initialize(json_file_path)
    @json_file_path = json_file_path
    @stats = {
      total_processed: 0,
      created: 0,
      updated: 0,
      skipped: 0,
      errors: []
    }
  end

  def import
    puts "\n" + "="*60
    puts "IMPORTING SCRAPED DEPUTIES DATA"
    puts "="*60
    puts "File: #{@json_file_path}"
    puts ""

    unless File.exist?(@json_file_path)
      puts "❌ Error: File not found: #{@json_file_path}"
      return false
    end

    data = load_json_file
    return false unless data

    process_districts(data)
    print_summary

    true
  end

  private

  def load_json_file
    puts "📖 Reading JSON file..."

    begin
      file_content = File.read(@json_file_path)
      data = JSON.parse(file_content)

      puts "✅ JSON loaded successfully"

      if data['metadata']
        puts "📊 Metadata:"
        puts "  - Scraped at: #{data['metadata']['scraped_at']}"
        puts "  - Total districts: #{data['metadata']['total_districts']}"
        puts "  - Total candidates: #{data['metadata']['total_candidates']}"
      end

      data
    rescue JSON::ParserError => e
      puts "❌ Error parsing JSON: #{e.message}"
      nil
    rescue StandardError => e
      puts "❌ Error reading file: #{e.message}"
      nil
    end
  end

  def process_districts(data)
    districts_data = data['districts'] || []

    puts "\n🏛️  Processing #{districts_data.length} districts..."
    puts ""

    districts_data.each_with_index do |district_data, index|
      process_district(district_data, index + 1, districts_data.length)
    end
  end

  def process_district(district_data, current, total)
    district_code = district_data['district_code']
    district_name = district_data['district_name']
    candidates_data = district_data['candidates'] || []

    puts "📍 [#{current}/#{total}] #{district_name} (#{candidates_data.length} candidates)"

    # Find electoral district
    electoral_district = ElectoralDistrict.find_by(code: district_code)

    unless electoral_district
      puts "   ⚠️  Electoral district not found: #{district_code}, skipping..."
      return
    end

    # Process each candidate
    candidates_data.each do |candidate_data|
      process_candidate(candidate_data, electoral_district)
    end

    puts "   ✅ Completed"
  end

  def process_candidate(candidate_data, electoral_district)
    @stats[:total_processed] += 1

    begin
      # Extract organization code
      org_code = candidate_data['idOrganizacionPolitica']&.to_s

      unless org_code
        @stats[:skipped] += 1
        return
      end

      # Find or create political organization
      political_organization = find_or_create_organization(candidate_data)

      unless political_organization
        @stats[:skipped] += 1
        return
      end

      # Find or initialize candidate
      candidate = Candidate.find_or_initialize_by(
        document_number: candidate_data['strDocumentoIdentidad'],
        position_type: candidate_data['strCargo'],
        political_organization: political_organization
      )

      is_new = candidate.new_record?

      # Update attributes
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
        department: candidate_data['strDepartamento'] || electoral_district.name,
        province: candidate_data['strProvincia'],
        district: candidate_data['strDistrito'],
        electoral_file_code: candidate_data['strCodExpedienteExt']
      )

      if candidate.save
        if is_new
          @stats[:created] += 1
          print "." if (@stats[:created] % 50).zero?
        else
          @stats[:updated] += 1
          print "u" if (@stats[:updated] % 50).zero?
        end
      else
        @stats[:skipped] += 1
        @stats[:errors] << {
          document: candidate_data['strDocumentoIdentidad'],
          name: "#{candidate_data['strNombres']} #{candidate_data['strApellidoPaterno']}",
          errors: candidate.errors.full_messages
        }
      end

    rescue StandardError => e
      @stats[:skipped] += 1
      @stats[:errors] << {
        document: candidate_data['strDocumentoIdentidad'],
        error: e.message
      }
    end
  end

  def find_or_create_organization(candidate_data)
    org_code = candidate_data['idOrganizacionPolitica']&.to_s

    organization = PoliticalOrganization.find_by(code: org_code)

    unless organization
      # Try to create if we have the data
      if candidate_data['strOrganizacionPolitica']
        organization = PoliticalOrganization.create(
          code: org_code,
          name: candidate_data['strOrganizacionPolitica'],
          organization_type: candidate_data['strTipoOrgPolitica'] || 'Partido Político',
          status: 'Inscrito'
        )
      end
    end

    organization
  end

  def print_summary
    puts "\n\n" + "="*60
    puts "IMPORT SUMMARY"
    puts "="*60
    puts "✅ Total processed: #{@stats[:total_processed]}"
    puts "➕ Created: #{@stats[:created]}"
    puts "🔄 Updated: #{@stats[:updated]}"
    puts "⏭️  Skipped: #{@stats[:skipped]}"
    puts "❌ Errors: #{@stats[:errors].length}"

    if @stats[:errors].any?
      puts "\n⚠️  Error Details (first 10):"
      @stats[:errors].first(10).each do |error|
        puts "  - #{error[:document]}: #{error[:name]}"
        if error[:errors]
          error[:errors].each { |e| puts "    • #{e}" }
        elsif error[:error]
          puts "    • #{error[:error]}"
        end
      end
    end

    puts "\n📊 Database Status:"
    puts "  - Total candidates: #{Candidate.count}"
    puts "  - Deputies: #{Candidate.deputies.count}"
    puts "  - Deputies by district:"

    Candidate.deputies
             .joins(:electoral_district)
             .group('electoral_districts.name')
             .count
             .sort_by { |_, count| -count }
             .first(10)
             .each do |district, count|
      puts "    • #{district}: #{count}"
    end

    puts "="*60
    puts ""
  end
end

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "\n❌ Usage: rails runner #{__FILE__} path/to/scraped_data.json"
    puts ""
    puts "Example:"
    puts "  rails runner lib/scrapers/import_scraped_deputies.rb data/diputados_20260204.json"
    puts ""
    exit 1
  end

  json_file = ARGV[0]
  importer = ImportScrapedDeputies.new(json_file)
  success = importer.import

  exit(success ? 0 : 1)
end
