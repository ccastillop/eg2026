#!/usr/bin/env ruby
# lib/scrapers/test_endpoint.rb
#
# Script de prueba para testear endpoints del JNE manualmente
#
# Uso:
#   ruby lib/scrapers/test_endpoint.rb

require 'net/http'
require 'json'
require 'uri'

class EndpointTester
  def initialize
    @base_url = 'https://votoinformado.jne.gob.pe'
  end

  def test_endpoint(endpoint_path, method: :get, params: {}, body: nil, headers: {})
    puts "\n" + "="*60
    puts "Testing Endpoint"
    puts "="*60
    puts "URL: #{@base_url}#{endpoint_path}"
    puts "Method: #{method.upcase}"
    puts "Params: #{params.inspect}" if params.any?
    puts "Body: #{body.inspect}" if body
    puts "Headers: #{headers.inspect}" if headers.any?
    puts "-"*60

    begin
      uri = build_uri(endpoint_path, params)
      http = setup_http(uri)
      request = build_request(uri, method, body, headers)

      puts "Making request..."
      response = http.request(request)

      puts "\nResponse Status: #{response.code} #{response.message}"
      puts "Response Headers:"
      response.each_header do |key, value|
        puts "  #{key}: #{value}"
      end

      puts "\nResponse Body (first 500 chars):"
      puts response.body[0..500]

      # Try to parse as JSON
      if response.content_type&.include?('json')
        data = JSON.parse(response.body)
        puts "\n✅ Valid JSON response"
        puts "Keys: #{data.keys.inspect}" if data.is_a?(Hash)
        puts "Array length: #{data.length}" if data.is_a?(Array)

        # Save to file
        filename = "tmp/test_response_#{Time.now.to_i}.json"
        File.write(filename, JSON.pretty_generate(data))
        puts "💾 Full response saved to: #{filename}"
      end

      response

    rescue StandardError => e
      puts "❌ Error: #{e.class} - #{e.message}"
      puts e.backtrace.first(5)
      nil
    end
  end

  def test_multiple_endpoints
    puts "\n🧪 Testing Multiple Possible Endpoints..."
    puts "="*60

    # List of possible endpoints to try
    endpoints = [
      '/api/candidatos',
      '/api/diputados',
      '/api/busqueda',
      '/api/candidatos/buscar',
      '/api/candidatos/diputados',
      '/Home/BuscarCandidatos',
      '/Home/ListaCandidatos',
      '/api/distrito',
      '/api/organizaciones',
    ]

    endpoints.each do |endpoint|
      puts "\nTrying: #{endpoint}"
      response = quick_test(endpoint)

      if response && response.is_a?(Net::HTTPSuccess)
        puts "  ✅ Success! (#{response.code})"
      elsif response
        puts "  ⚠️  Response: #{response.code} #{response.message}"
      else
        puts "  ❌ Failed"
      end

      sleep 1 # Be nice to the server
    end
  end

  def quick_test(endpoint_path)
    uri = URI("#{@base_url}#{endpoint_path}")
    http = setup_http(uri)
    request = Net::HTTP::Get.new(uri)
    add_default_headers(request)

    begin
      http.request(request)
    rescue
      nil
    end
  end

  private

  def build_uri(endpoint_path, params)
    uri = URI("#{@base_url}#{endpoint_path}")

    if params.any?
      uri.query = URI.encode_www_form(params)
    end

    uri
  end

  def setup_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.open_timeout = 10
    http.read_timeout = 30
    http
  end

  def build_request(uri, method, body, custom_headers)
    request = case method.to_sym
    when :get
      Net::HTTP::Get.new(uri)
    when :post
      Net::HTTP::Post.new(uri)
    when :put
      Net::HTTP::Put.new(uri)
    else
      Net::HTTP::Get.new(uri)
    end

    add_default_headers(request)

    # Add custom headers
    custom_headers.each do |key, value|
      request[key] = value
    end

    # Add body if present
    if body
      request.body = body.is_a?(String) ? body : JSON.generate(body)
      request['Content-Type'] = 'application/json' unless request['Content-Type']
    end

    request
  end

  def add_default_headers(request)
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
    request['Accept'] = 'application/json, text/plain, */*'
    request['Accept-Language'] = 'es-PE,es;q=0.9,en;q=0.8'
    request['Referer'] = "#{@base_url}/diputados"
  end
end

# =============================================================================
# EXAMPLES - Uncomment to test different scenarios
# =============================================================================

if __FILE__ == $0
  tester = EndpointTester.new

  puts "\n🚀 JNE Endpoint Tester"
  puts "="*60
  puts "Este script te ayuda a probar diferentes endpoints del JNE"
  puts ""

  # Create tmp directory if it doesn't exist
  Dir.mkdir('tmp') unless Dir.exist?('tmp')

  # EJEMPLO 1: Test a specific endpoint
  puts "\n📍 EJEMPLO 1: Testing a specific endpoint"
  tester.test_endpoint(
    '/api/candidatos',
    method: :get,
    params: {
      distrito: 'LIMA',
      tipo: 'diputado'
    }
  )

  # EJEMPLO 2: Test with POST
  # Uncomment to test:
  # puts "\n📍 EJEMPLO 2: Testing with POST"
  # tester.test_endpoint(
  #   '/api/buscar',
  #   method: :post,
  #   body: {
  #     idDistrito: '150000',
  #     idTipoEleccion: 15,
  #     idProceso: 124
  #   }
  # )

  # EJEMPLO 3: Test multiple possible endpoints
  # Uncomment to scan:
  # puts "\n📍 EJEMPLO 3: Scanning multiple endpoints"
  # tester.test_multiple_endpoints

  puts "\n" + "="*60
  puts "✅ Testing complete!"
  puts "="*60
  puts ""
  puts "📝 Next steps:"
  puts "1. Review the responses in tmp/ directory"
  puts "2. Find the working endpoint"
  puts "3. Update lib/scrapers/jne_deputies_scraper.rb with the correct URL"
  puts "4. See lib/scrapers/HOWTO_DISCOVER_ENDPOINTS.md for more guidance"
  puts ""
end
