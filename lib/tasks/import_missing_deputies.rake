# lib/tasks/import_missing_deputies.rake
namespace :candidates do
  desc "Import missing deputies from seed file (those with incorrect ubigeos but valid jury assignments)"
  task import_missing_deputies: :environment do
    require 'json'

    puts "=" * 80
    puts "IMPORTING MISSING DEPUTIES FROM SEED FILE"
    puts "=" * 80
    puts

    # Map electoral jury names to electoral districts
    jury_to_district = {
      'LIMA OESTE 3' => 'Lima',
      'LIMA OESTE 1' => 'Lima',
      'LIMA OESTE 2' => 'Lima',
      'LIMA ESTE 1' => 'Lima',
      'LIMA ESTE 2' => 'Lima',
      'LIMA ESTE 3' => 'Lima',
      'LIMA SUR 1' => 'Lima',
      'LIMA SUR 2' => 'Lima',
      'LIMA SUR 3' => 'Lima',
      'LIMA CENTRO 1' => 'Lima',
      'LIMA CENTRO 2' => 'Lima',
      'LIMA NORTE 1' => 'Lima',
      'LIMA NORTE 2' => 'Lima',
      'LIMA NORTE 3' => 'Lima'
    }

    file_path = Rails.root.join('data', '02_Diputados.json')

    unless File.exist?(file_path)
      puts "❌ File not found: #{file_path}"
      exit 1
    end

    puts "📖 Reading deputies seed file..."
    file_content = File.read(file_path)
    data = JSON.parse(file_content)
    candidates_data = data['data']

    puts "✅ Found #{candidates_data.length} total candidates in seed file"
    puts

    # Filter candidates that are from Lima juries but have wrong ubigeos (140100)
    missing_candidates = candidates_data.select do |c|
      jury_name = c['strJuradoElectoralCreacion']
      ubigeo = c['strUbigeo']

      # Look for candidates with Lima juries but wrong ubigeos
      jury_to_district.key?(jury_name) && ubigeo == '140100'
    end

    puts "🔍 Found #{missing_candidates.length} candidates with Lima jury but incorrect ubigeo (140100)"
    puts

    if missing_candidates.empty?
      puts "✅ No missing candidates to import"
      return
    end

    # Show breakdown by organization
    puts "Breakdown by political organization:"
    missing_candidates.group_by { |c| c['strOrganizacionPolitica'] }.each do |org_name, candidates|
      puts "  #{org_name}: #{candidates.length} candidates"
    end
    puts

    created_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0

    puts "🔄 Importing candidates..."

    missing_candidates.each_with_index do |candidate_data, index|
      begin
        # Find political organization
        org_code = candidate_data['idOrganizacionPolitica']&.to_s

        unless org_code.present?
          skipped_count += 1
          next
        end

        political_organization = PoliticalOrganization.find_by(code: org_code)

        unless political_organization
          political_organization = PoliticalOrganization.create!(
            code: org_code,
            name: candidate_data['strOrganizacionPolitica'] || "Unknown Organization #{org_code}",
            organization_type: candidate_data['strTipoOrgPolitica'] || 'Partido Político',
            status: 'Inscrito'
          )
        end

        # Map electoral jury to district
        jury_name = candidate_data['strJuradoElectoralCreacion']
        district_name = jury_to_district[jury_name]

        electoral_district = nil
        if district_name
          electoral_district = ElectoralDistrict.find_by(name: district_name)
        end

        # Find or initialize candidate
        candidate = Candidate.find_or_initialize_by(
          document_number: candidate_data['strDocumentoIdentidad'],
          position_type: 'DIPUTADO',
          political_organization: political_organization
        )

        is_new = candidate.new_record?

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
          department: 'LIMA', # Fix the department
          province: candidate_data['strProvincia'],
          district: candidate_data['strDistrito'],
          electoral_file_code: candidate_data['strCodExpedienteExt']
        )

        if candidate.save
          if is_new
            created_count += 1
          else
            updated_count += 1
          end
          print "." if (created_count + updated_count) % 10 == 0
        else
          error_count += 1
          if error_count <= 5
            puts "\n  ⚠️  Failed to save: #{candidate.full_name} - #{candidate.errors.full_messages.join(', ')}"
          end
        end

      rescue StandardError => e
        error_count += 1
        if error_count <= 5
          puts "\n  ❌ Error importing candidate: #{e.message}"
        end
      end
    end

    puts "\n"
    puts
    puts "=" * 80
    puts "IMPORT RESULTS"
    puts "=" * 80
    puts "  ✅ Created: #{created_count}"
    puts "  🔄 Updated: #{updated_count}"
    puts "  ⏭️  Skipped: #{skipped_count}"
    puts "  ❌ Errors: #{error_count}"
    puts

    # Verify specific candidates
    puts "🔍 Verifying specific candidates:"
    test_names = [
      ['COLCHADO', 'HUAMANI'],
      ['HUILCA', 'FLORES'],
      ['SALCEDO', 'CUADROS']
    ]

    test_names.each do |paternal, maternal|
      candidate = Candidate.deputies
                          .where(paternal_surname: paternal, maternal_surname: maternal)
                          .first
      if candidate
        puts "  ✅ #{candidate.full_name} - #{candidate.electoral_district&.name || 'No district'} - #{candidate.political_organization.name}"
      else
        puts "  ❌ Not found: #{paternal} #{maternal}"
      end
    end
    puts

    puts "📊 Final Statistics:"
    puts "  Total deputies: #{Candidate.deputies.count}"
    puts "  Deputies with district: #{Candidate.deputies.where.not(electoral_district_id: nil).count}"
    lima_district = ElectoralDistrict.find_by(name: 'Lima')
    if lima_district
      lima_count = Candidate.deputies.where(electoral_district: lima_district).count
      puts "  Lima deputies: #{lima_count}"
    end
    puts "=" * 80
  end
end
