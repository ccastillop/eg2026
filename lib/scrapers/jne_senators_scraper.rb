# lib/scrapers/jne_senators_scraper.rb
require 'net/http'
require 'json'
require 'uri'

module Scrapers
  class JneSenatorsScaper
    # Real JNE API endpoint discovered
    BASE_URL = 'https://sije.jne.gob.pe'
    API_ENDPOINT = '/ServiciosWeb/WSCandidato/ListaCandidatos'

    # Authentication token (from the curl request)
    AUTH_TOKEN = '1454eebb-4b05-4400-93ac-25f0d0690d4b'
    USER_ID = 1381

    # Electoral process ID for 2026
    PROCESO_ELECTORAL_2026 = 124
    TIPO_ELECCION_SENADORES_DISTRITO_UNICO = 20
    TIPO_ELECCION_SENADORES_DISTRITO_MULTIPLE = 21

    def initialize
      @results = []
      @errors = []
      @request_count = 0
    end

    # Main method to scrape all senators
    def scrape_all_senators
      puts "\n🔍 Starting JNE Senators Scraper..."
      puts "="*60
      puts "Using real JNE API: #{BASE_URL}#{API_ENDPOINT}"
      puts ""

      # Scrape both types of senators
      scrape_senators_single_district
      scrape_senators_multiple_district

      print_summary

      @results
    end

    # Scrape senators from single district (Distrito Único)
    def scrape_senators_single_district
      puts "\n📍 Processing: Senators - Single District (Distrito Único)..."

      begin
        candidates_data = fetch_senators(TIPO_ELECCION_SENADORES_DISTRITO_UNICO, 'DISTRITO_UNICO')

        if candidates_data && candidates_data.any?
          @results << {
            election_type: 'SENADORES_DISTRITO_UNICO',
            tipo_eleccion_id: TIPO_ELECCION_SENADORES_DISTRITO_UNICO,
            candidates: candidates_data,
            count: candidates_data.length
          }
          puts "   ✅ Found #{candidates_data.length} candidates"
        else
          puts "   ⚠️  No candidates found"
        end
      rescue StandardError => e
        handle_error('SENADORES_DISTRITO_UNICO', e)
      end
    end

    # Scrape senators from multiple districts (Distrito Múltiple)
    # Note: The JNE API returns ALL multiple-district senators regardless of district filter
    # So we only need to call it once instead of per district
    def scrape_senators_multiple_district
      puts "\n📍 Processing: Senators - Multiple District (Distrito Múltiple)..."
      puts "   Note: API returns all senators for this type (not filtered by district)"

      begin
        # Call with empty ubigeo to get all multiple-district senators at once
        candidates_data = fetch_senators(TIPO_ELECCION_SENADORES_DISTRITO_MULTIPLE, '')

        if candidates_data && candidates_data.any?
          @results << {
            election_type: 'SENADORES_DISTRITO_MULTIPLE',
            tipo_eleccion_id: TIPO_ELECCION_SENADORES_DISTRITO_MULTIPLE,
            candidates: candidates_data,
            count: candidates_data.length
          }
          puts "   ✅ Found #{candidates_data.length} candidates (national list)"
        else
          puts "   ⚠️  No candidates found"
        end
      rescue StandardError => e
        handle_error('SENADORES_DISTRITO_MULTIPLE', e)
      end
    end

    # Note: scrape_senators_by_district and fetch_senators_for_district methods removed
    # They are no longer needed since Multiple District senators are fetched in one call

    # Fetch senators (Single District type - no specific district)
    def fetch_senators(tipo_eleccion_id, ubigeo = '')
      payload = build_payload(tipo_eleccion_id, ubigeo)
      response = make_request(payload)

      @request_count += 1

      if response && response['data'].is_a?(Array)
        response['data']
      elsif response && response['message']
        nil
      else
        puts "   ⚠️  Unexpected response structure. Keys: #{response&.keys}"
        nil
      end
    end

    # Build the API request payload
    def build_payload(tipo_eleccion_id, ubigeo = '')
      {
        oToken: {
          AuthToken: AUTH_TOKEN,
          UserId: USER_ID
        },
        oFiltro: {
          idProcesoElectoral: PROCESO_ELECTORAL_2026,
          strUbiDistrito: ubigeo,
          idTipoEleccion: tipo_eleccion_id
        }
      }
    end

    # Make HTTP request to JNE API
    def make_request(payload)
      uri = URI("#{BASE_URL}#{API_ENDPOINT}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 30

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = payload.to_json

      response = http.request(request)

      if response.code == '200'
        JSON.parse(response.body)
      else
        puts "   ❌ HTTP Error: #{response.code} - #{response.message}"
        nil
      end
    rescue StandardError => e
      puts "   ❌ Request Error: #{e.message}"
      nil
    end

    # Handle errors
    def handle_error(context, error)
      @errors << { context: context, error: error.message }
      puts "   ❌ Error: #{error.message}"
    end

    # Print summary of scraping results
    def print_summary
      puts "\n"
      puts "="*60
      puts "SCRAPING SUMMARY"
      puts "="*60

      total_candidates = @results.sum { |r| r[:count] || 0 }
      single_district_count = @results.find { |r| r[:election_type] == 'SENADORES_DISTRITO_UNICO' }&.dig(:count) || 0
      multiple_district_count = @results.find { |r| r[:election_type] == 'SENADORES_DISTRITO_MULTIPLE' }&.dig(:count) || 0

      puts "✅ Successfully processed: #{@results.length} batches"
      puts "📊 Total candidates found: #{total_candidates}"
      puts "   - Single District (Distrito Único): #{single_district_count}"
      puts "   - Multiple District (national list): #{multiple_district_count}"
      puts "🌐 Total API requests: #{@request_count}"
      puts "❌ Errors encountered: #{@errors.length}"

      puts "="*60
      puts ""
    end

    # Save results to JSON file
    def save_to_json(filename = nil)
      filename ||= Rails.root.join('tmp', "scraped_senators_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json")

      data = {
        scraped_at: Time.now.iso8601,
        total_batches: @results.length,
        total_candidates: @results.sum { |r| r[:count] || 0 },
        results: @results.map do |result|
          {
            election_type: result[:election_type],
            tipo_eleccion_id: result[:tipo_eleccion_id],
            count: result[:count],
            candidates: result[:candidates]
          }
        end
      }

      File.write(filename, JSON.pretty_generate(data))
      puts "\n💾 Data saved to: #{filename}"

      filename
    end
  end
end
