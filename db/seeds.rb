# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "\n" + "="*60
puts "SEEDING DATABASE - Elecciones Generales 2026"
puts "="*60
puts "\n"

# Load political organizations first (since candidates depend on them)
load Rails.root.join('db', 'seeds', 'political_organizations.rb')

# Load candidates
load Rails.root.join('db', 'seeds', 'candidates.rb')

puts "="*60
puts "SEEDING COMPLETED!"
puts "="*60
puts "\n"
