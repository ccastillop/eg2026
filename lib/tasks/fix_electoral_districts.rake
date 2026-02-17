# lib/tasks/fix_electoral_districts.rake
namespace :candidates do
  desc "Fix electoral district assignments for candidates based on department field"
  task fix_electoral_districts: :environment do
    puts "=" * 80
    puts "FIXING ELECTORAL DISTRICT ASSIGNMENTS"
    puts "=" * 80
    puts

    # Count before
    before_with_district = Candidate.where.not(electoral_district_id: nil).count
    before_without_district = Candidate.where(electoral_district_id: nil).count

    puts "BEFORE:"
    puts "  Candidates with district: #{before_with_district}"
    puts "  Candidates without district: #{before_without_district}"
    puts

    # Department name mappings (from JSON to district name)
    dept_mappings = {
      'AMAZONAS' => 'Amazonas',
      'ANCASH' => 'Áncash',
      'APURIMAC' => 'Apurímac',
      'AREQUIPA' => 'Arequipa',
      'AYACUCHO' => 'Ayacucho',
      'CAJAMARCA' => 'Cajamarca',
      'CALLAO' => 'Callao',
      'CUSCO' => 'Cusco',
      'HUANCAVELICA' => 'Huancavelica',
      'HUANUCO' => 'Huánuco',
      'ICA' => 'Ica',
      'JUNIN' => 'Junín',
      'LA LIBERTAD' => 'La Libertad',
      'LA_LIBERTAD' => 'La Libertad',
      'LAMBAYEQUE' => 'Lambayeque',
      'LIMA' => 'Lima',
      'LIMA PROVINCIAS' => 'Lima Provincias',
      'LIMA_PROVINCIAS' => 'Lima Provincias',
      'LORETO' => 'Loreto',
      'MADRE DE DIOS' => 'Madre de Dios',
      'MADRE_DE_DIOS' => 'Madre de Dios',
      'MOQUEGUA' => 'Moquegua',
      'PASCO' => 'Pasco',
      'PIURA' => 'Piura',
      'PUNO' => 'Puno',
      'SAN MARTIN' => 'San Martín',
      'SAN_MARTIN' => 'San Martín',
      'TACNA' => 'Tacna',
      'TUMBES' => 'Tumbes',
      'UCAYALI' => 'Ucayali'
    }

    # Process candidates without district
    candidates_to_fix = Candidate.where(electoral_district_id: nil)
                                .where.not(department: [nil, ''])

    puts "Processing #{candidates_to_fix.count} candidates with department but no district..."
    puts

    updated_count = 0
    skipped_count = 0
    error_count = 0

    candidates_to_fix.find_each do |candidate|
      begin
        dept = candidate.department.strip.upcase

        # Try to find district using mapping
        district_name = dept_mappings[dept]

        if district_name
          district = ElectoralDistrict.find_by(name: district_name)

          if district
            candidate.update!(electoral_district: district)
            updated_count += 1
            print "." if updated_count % 100 == 0
          else
            skipped_count += 1
            puts "\n  ⚠️  District not found for: #{district_name}" if skipped_count <= 5
          end
        else
          skipped_count += 1
          puts "\n  ⚠️  No mapping for department: '#{dept}'" if skipped_count <= 5
        end
      rescue StandardError => e
        error_count += 1
        puts "\n  ❌ Error updating candidate #{candidate.id}: #{e.message}" if error_count <= 5
      end
    end

    puts "\n"
    puts

    # Count after
    after_with_district = Candidate.where.not(electoral_district_id: nil).count
    after_without_district = Candidate.where(electoral_district_id: nil).count

    puts "=" * 80
    puts "RESULTS:"
    puts "=" * 80
    puts "  ✅ Updated: #{updated_count}"
    puts "  ⏭️  Skipped: #{skipped_count}"
    puts "  ❌ Errors: #{error_count}"
    puts
    puts "AFTER:"
    puts "  Candidates with district: #{after_with_district} (was #{before_with_district})"
    puts "  Candidates without district: #{after_without_district} (was #{before_without_district})"
    puts
    puts "BREAKDOWN BY POSITION:"
    ['DIPUTADO', 'SENADOR', 'PRESIDENTE DE LA REPÚBLICA'].each do |position|
      total = Candidate.where(position_type: position).count
      with_dist = Candidate.where(position_type: position).where.not(electoral_district_id: nil).count
      without_dist = total - with_dist
      percentage = total > 0 ? (with_dist * 100.0 / total).round(1) : 0
      puts "  #{position}:"
      puts "    With district: #{with_dist} / #{total} (#{percentage}%)"
      puts "    Without district: #{without_dist}"
    end
    puts "=" * 80
  end
end
