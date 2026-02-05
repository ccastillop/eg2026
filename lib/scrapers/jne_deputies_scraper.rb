# lib/scrapers/jne_deputies_scraper.rb
require 'net/http'
require 'json'
require 'uri'

module Scrapers
  class JneDeputiesScraper
    # Real JNE API endpoint discovered
    BASE_URL = 'https://sije.jne.gob.pe'
    API_ENDPOINT = '/ServiciosWeb/WSCandidato/ListaCandidatos'

    # Authentication token (from the curl request)
    AUTH_TOKEN = '1454eebb-4b05-4400-93ac-25f0d0690d4b'
    USER_ID = 1381

    # Electoral process ID for 2026
    PROCESO_ELECTORAL_2026 = 124
    TIPO_ELECCION_DIPUTADOS = 15

    def initialize
      @results = []
      @errors = []
      @request_count = 0
    end

    # Main method to scrape all deputies
    def scrape_all_deputies
      puts "\n🔍 Starting JNE Deputies Scraper..."
      puts "="*60
      puts "Using real JNE API: #{BASE_URL}#{API_ENDPOINT}"
      puts ""

      electoral_districts = ElectoralDistrict.departments.ordered

      puts "Found #{electoral_districts.count} electoral districts to process"
      puts ""

      electoral_districts.each_with_index do |district, index|
        scrape_district(district, index + 1, electoral_districts.count)

        # Be nice to the server - wait between requests
        sleep 2 if index < electoral_districts.count - 1
      end

      print_summary

      @results
    end

    # Scrape candidates for a specific district
    def scrape_district(district, current = 1, total = 1)
      puts "📍 [#{current}/#{total}] Processing: #{district.name} (#{district.code})..."

      begin
        candidates_data = fetch_candidates_for_district(district)

        if candidates_data && candidates_data.any?
          @results << {
            district: district,
            candidates: candidates_data,
            count: candidates_data.length
          }
          puts "   ✅ Found #{candidates_data.length} candidates"
        else
          puts "   ⚠️  No candidates found"
        end

      rescue StandardError => e
        @errors << { district: district.name, error: e.message }
        puts "   ❌ Error: #{e.message}"
      end
    end

    # Fetch candidates for a specific district using the real API
    def fetch_candidates_for_district(district)
      @request_count += 1

      url = "#{BASE_URL}#{API_ENDPOINT}"

      # Build request body matching the curl example
      request_body = {
        oToken: {
          AuthToken: AUTH_TOKEN,
          UserId: USER_ID
        },
        oFiltro: {
          idProcesoElectoral: PROCESO_ELECTORAL_2026,
          strUbiDepartamento: district.ubigeo,
          idTipoEleccion: TIPO_ELECCION_DIPUTADOS
        }
      }

      response_body = make_http_request(url, request_body)
      parse_response(response_body)
    end

    # Make HTTP POST request with proper headers
    def make_http_request(url, body)
      uri = URI(url)

      # Set up HTTP with timeout
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      http.open_timeout = 15
      http.read_timeout = 45

      # Create POST request
      request = Net::HTTP::Post.new(uri)

      # Add headers from the curl request
      request['Accept'] = 'application/json, text/plain, */*'
      request['Accept-Language'] = 'es-ES,es;q=0.9,en;q=0.8'
      request['Content-Type'] = 'application/json'
      request['Origin'] = 'https://votoinformado.jne.gob.pe'
      request['Referer'] = 'https://votoinformado.jne.gob.pe/'
      request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36'

      # Set request body
      request.body = JSON.generate(body)

      # Make request
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "HTTP Error: #{response.code} #{response.message}"
      end

      response.body
    end

    # Parse JSON response
    def parse_response(response_body)
      data = JSON.parse(response_body)

      # The JNE API typically returns data in a 'Data' or 'data' key
      # Adjust based on the actual response structure
      if data.is_a?(Hash)
        # Try common patterns
        candidates = data['Data'] || data['data'] || data['candidatos'] || data['Candidatos']

        if candidates.is_a?(Array)
          return candidates
        elsif data.is_a?(Array)
          return data
        else
          # Handle nested structure like {"data": {"Data": [...]}}
          if data['data'].is_a?(Hash) && data['data']['Data'].is_a?(Array)
            return data['data']['Data']
          elsif data['data'].is_a?(Hash) && data['data']['data'].is_a?(Array)
            return data['data']['data']
          end
        end
      elsif data.is_a?(Array)
        return data
      end

      # If we can't find the data, log structure for debugging
      if data.is_a?(Hash)
        puts "   ⚠️  Unexpected response structure. Keys: #{data.keys.inspect}"
        # Try to log first level nested keys if available
        if data['data'].is_a?(Hash)
          puts "   ⚠️  Nested 'data' keys: #{data['data'].keys.inspect}"
        end
      end
      []
    rescue JSON::ParserError => e
      puts "   ❌ JSON Parse Error: #{e.message}"
      []
    end

    # Save results to JSON file
    def save_to_json(filename = nil)
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      filename ||= Rails.root.join('data', "diputados_completo_#{timestamp}.json")

      output = {
        metadata: {
          scraped_at: Time.now.iso8601,
          source: "JNE API (#{BASE_URL}#{API_ENDPOINT})",
          total_districts: @results.length,
          total_candidates: @results.sum { |r| r[:count] },
          total_requests: @request_count,
          errors: @errors.length
        },
        districts: @results.map do |result|
          {
            district_code: result[:district].code,
            district_name: result[:district].name,
            district_ubigeo: result[:district].ubigeo,
            candidates_count: result[:count],
            candidates: result[:candidates]
          }
        end,
        errors: @errors
      }

      File.write(filename, JSON.pretty_generate(output))
      puts "\n💾 Data saved to: #{filename}"

      filename
    end

    # Print summary of scraping results
    def print_summary
      puts "\n" + "="*60
      puts "SCRAPING SUMMARY"
      puts "="*60
      puts "✅ Successfully processed: #{@results.length} districts"
      puts "📊 Total candidates found: #{@results.sum { |r| r[:count] }}"
      puts "🌐 Total API requests: #{@request_count}"
      puts "❌ Errors encountered: #{@errors.length}"

      if @errors.any?
        puts "\nErrors:"
        @errors.each do |error|
          puts "  - #{error[:district]}: #{error[:error]}"
        end
      end

      if @results.any?
        puts "\nTop 10 Districts by Candidate Count:"
        @results.sort_by { |r| -r[:count] }
                .first(10)
                .each do |result|
          puts "  - #{result[:district].name}: #{result[:count]} candidates"
        end
      end

      puts "="*60
      puts ""
    end

    # Test a single district (useful for debugging)
    def test_single_district(district_code)
      puts "\n🧪 Testing single district: #{district_code}"
      puts "="*60

      district = ElectoralDistrict.find_by(code: district_code)

      unless district
        puts "❌ District not found: #{district_code}"
        return nil
      end

      scrape_district(district)

      if @results.any?
        result = @results.last
        puts "\n✅ Test successful!"
        puts "Found #{result[:count]} candidates"

        if result[:candidates].any?
          puts "\nSample candidate:"
          sample = result[:candidates].first
          puts "  Name: #{sample['strNombres']} #{sample['strApellidoPaterno']} #{sample['strApellidoMaterno']}"
          puts "  DNI: #{sample['strDocumentoIdentidad']}"
          puts "  Organization: #{sample['strOrganizacionPolitica']}"
          puts "  Position: #{sample['intPosicion']}"
        end
      else
        puts "❌ Test failed - no results"
      end

      result
    end
  end
end

# Usage examples:
#
# Test with a single district:
#   rails runner -e production <<-RUBY
#     require './lib/scrapers/jne_deputies_scraper'
#     scraper = Scrapers::JneDeputiesScraper.new
#     scraper.test_single_district('LIMA')
#   RUBY
#
# Scrape all districts:
#   rails runner -e production <<-RUBY
#     require './lib/scrapers/jne_deputies_scraper'
#     scraper = Scrapers::JneDeputiesScraper.new
#     scraper.scrape_all_deputies
#     scraper.save_to_json
#   RUBY
#
# Scrape and import in one go:
#   rails runner -e production <<-RUBY
#     require './lib/scrapers/jne_deputies_scraper'
#     scraper = Scrapers::JneDeputiesScraper.new
#     scraper.scrape_all_deputies
#     json_file = scraper.save_to_json
#
#     # Import the data
#     require './lib/scrapers/import_scraped_deputies'
#     importer = ImportScrapedDeputies.new(json_file)
#     importer.import
#   RUBY
