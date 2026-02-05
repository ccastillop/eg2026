# db/seeds/electoral_districts.rb
puts "Loading Electoral Districts..."

# Electoral districts data for Peru 2026
# Based on the new bicameral system with deputies by department
districts_data = [
  { code: 'AMAZONAS', name: 'Amazonas', district_type: 'department', seats_count: 3, ubigeo: '010000' },
  { code: 'ANCASH', name: 'Áncash', district_type: 'department', seats_count: 6, ubigeo: '020000' },
  { code: 'APURIMAC', name: 'Apurímac', district_type: 'department', seats_count: 3, ubigeo: '030000' },
  { code: 'AREQUIPA', name: 'Arequipa', district_type: 'department', seats_count: 7, ubigeo: '040000' },
  { code: 'AYACUCHO', name: 'Ayacucho', district_type: 'department', seats_count: 4, ubigeo: '050000' },
  { code: 'CAJAMARCA', name: 'Cajamarca', district_type: 'department', seats_count: 7, ubigeo: '060000' },
  { code: 'CALLAO', name: 'Callao', district_type: 'department', seats_count: 5, ubigeo: '070000' },
  { code: 'CUSCO', name: 'Cusco', district_type: 'department', seats_count: 7, ubigeo: '080000' },
  { code: 'HUANCAVELICA', name: 'Huancavelica', district_type: 'department', seats_count: 3, ubigeo: '090000' },
  { code: 'HUANUCO', name: 'Huánuco', district_type: 'department', seats_count: 5, ubigeo: '100000' },
  { code: 'ICA', name: 'Ica', district_type: 'department', seats_count: 4, ubigeo: '110000' },
  { code: 'JUNIN', name: 'Junín', district_type: 'department', seats_count: 7, ubigeo: '120000' },
  { code: 'LA LIBERTAD', name: 'La Libertad', district_type: 'department', seats_count: 9, ubigeo: '130000' },
  { code: 'LAMBAYEQUE', name: 'Lambayeque', district_type: 'department', seats_count: 6, ubigeo: '140000' },
  { code: 'LIMA', name: 'Lima', district_type: 'department', seats_count: 50, ubigeo: '150000' },
  { code: 'LIMA_PROVINCIAS', name: 'Lima Provincias', district_type: 'department', seats_count: 5, ubigeo: '150100' },
  { code: 'LORETO', name: 'Loreto', district_type: 'department', seats_count: 5, ubigeo: '160000' },
  { code: 'MADRE_DE_DIOS', name: 'Madre de Dios', district_type: 'department', seats_count: 1, ubigeo: '170000' },
  { code: 'MOQUEGUA', name: 'Moquegua', district_type: 'department', seats_count: 1, ubigeo: '180000' },
  { code: 'PASCO', name: 'Pasco', district_type: 'department', seats_count: 2, ubigeo: '190000' },
  { code: 'PIURA', name: 'Piura', district_type: 'department', seats_count: 9, ubigeo: '200000' },
  { code: 'PUNO', name: 'Puno', district_type: 'department', seats_count: 7, ubigeo: '210000' },
  { code: 'SAN_MARTIN', name: 'San Martín', district_type: 'department', seats_count: 5, ubigeo: '220000' },
  { code: 'TACNA', name: 'Tacna', district_type: 'department', seats_count: 2, ubigeo: '230000' },
  { code: 'TUMBES', name: 'Tumbes', district_type: 'department', seats_count: 1, ubigeo: '240000' },
  { code: 'UCAYALI', name: 'Ucayali', district_type: 'department', seats_count: 3, ubigeo: '250000' },
  { code: 'EXTRANJERO', name: 'Peruanos en el Extranjero', district_type: 'abroad', seats_count: 2, ubigeo: '999999' }
]

created_count = 0
updated_count = 0
skipped_count = 0

districts_data.each do |district_data|
  begin
    district = ElectoralDistrict.find_or_initialize_by(code: district_data[:code])

    is_new = district.new_record?

    district.assign_attributes(district_data)

    if district.save
      if is_new
        created_count += 1
        print "."
      else
        updated_count += 1
        print "u"
      end
    else
      skipped_count += 1
      puts "\n  ⚠️  Failed to save district #{district_data[:code]}: #{district.errors.full_messages.join(', ')}"
    end

  rescue StandardError => e
    skipped_count += 1
    puts "\n  ❌ Error processing district #{district_data[:code]}: #{e.message}"
  end
end

puts "\n"
puts "  ✅ Created: #{created_count} electoral districts"
puts "  🔄 Updated: #{updated_count} electoral districts" if updated_count > 0
puts "  ⚠️  Skipped: #{skipped_count} electoral districts" if skipped_count > 0
puts "  📊 Total in DB: #{ElectoralDistrict.count}"
puts "  🏛️  Total seats: #{ElectoralDistrict.sum(:seats_count)}"
puts ""
