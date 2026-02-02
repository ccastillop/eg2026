# Database Seeding - Elecciones Generales 2026

This directory contains the seed scripts for loading electoral data from JSON files into the database.

## Structure

```
db/seeds/
├── README.md                      # This file
├── political_organizations.rb     # Seeds political organizations (parties & alliances)
├── candidates.rb                  # Seeds all candidates (presidents, deputies, senators)
└── verify_data.rb                 # Verification script to check data integrity
```

## Data Source

The seed scripts read JSON files from the `data/` directory:

- `00_OrganizacionPolitica.json` - Political parties and electoral alliances
- `01_Presidentes.json` - Presidential and vice-presidential candidates
- `02_Diputados.json` - Deputy candidates
- `03_SenadoresDistritoUnico.json` - Senators for single district
- `04_SenadoresDistritoMultiple.json` - Senators for multiple districts

## Usage

### Run All Seeds

To seed the entire database:

```bash
rails db:seed
```

This will:
1. Load all political organizations
2. Load all candidates from all files
3. Display progress and summary statistics

### Run Individual Seed Files

You can also run individual seed files:

```bash
# Load only political organizations
rails runner db/seeds/political_organizations.rb

# Load only candidates
rails runner db/seeds/candidates.rb

# Verify data integrity
rails runner db/seeds/verify_data.rb
```

### Reset and Reseed

To completely reset the database and reseed:

```bash
rails db:reset
```

Or to just drop, create, migrate and seed:

```bash
rails db:drop db:create db:migrate db:seed
```

## Database Schema

### Political Organizations Table

Stores information about political parties and electoral alliances:

- `code` - Unique organization code (from ONPE)
- `name` - Full organization name
- `acronym` - Organization acronym
- `organization_type` - Type (Partido Político, Alianza Electoral)
- `status` - Current status (Inscrito, Cancelado, etc.)
- `registration_date` - Date of registration
- `cancellation_date` - Date of cancellation (if applicable)
- `website` - Organization website
- `address` - Physical address
- `logo_url` - URL/path to organization logo

### Candidates Table

Stores information about all candidates:

- `political_organization_id` - Foreign key to political_organizations
- `position_type` - Type of position (PRESIDENTE, DIPUTADO, SENADOR, etc.)
- `position_number` - Position number in the list
- `document_type` - Type of identification document
- `document_number` - Document number (DNI, etc.)
- `first_name` - Candidate's first name
- `paternal_surname` - Paternal surname
- `maternal_surname` - Maternal surname
- `gender` - Gender (MASCULINO, FEMENINO)
- `birth_date` - Date of birth
- `is_native` - Whether the candidate is a native person
- `status` - Candidacy status (INSCRITO, ADMITIDO, etc.)
- `photo_guid` - Unique identifier for photo
- `photo_filename` - Photo filename
- `department` - Department (region)
- `province` - Province
- `district` - District
- `electoral_file_code` - Electoral file code

## Models and Relationships

### PoliticalOrganization Model

```ruby
# Associations
has_many :candidates

# Validations
validates :code, presence: true, uniqueness: true
validates :name, presence: true

# Scopes
PoliticalOrganization.active
PoliticalOrganization.political_parties
PoliticalOrganization.alliances
```

### Candidate Model

```ruby
# Associations
belongs_to :political_organization

# Validations
validates :document_number, presence: true
validates :position_type, presence: true

# Scopes
Candidate.presidents
Candidate.vice_presidents
Candidate.deputies
Candidate.senators
Candidate.by_department(dept)
Candidate.active
```

## Data Statistics

After seeding, you should expect approximately:

- **46** Political Organizations
- **2,591** Total Candidates
  - 36 Presidential candidates
  - 72 Vice-presidential candidates (36 first, 36 second)
  - 1,208 Deputy candidates
  - 1,275 Senate candidates

## Features

### Idempotent Seeds

The seed scripts are **idempotent**, meaning you can run them multiple times safely:

- Uses `find_or_initialize_by` to avoid duplicates
- Updates existing records if data has changed
- Displays counts of created/updated/skipped records

### Progress Indicators

- `.` - Created record (shown every 10 or 50 records)
- `u` - Updated record
- Visual summary at the end of each file

### Error Handling

- Gracefully handles missing files
- Reports validation errors
- Continues processing even if individual records fail
- Shows summary of skipped records

## Data Integrity Checks

Run the verification script to check data quality:

```bash
rails runner db/seeds/verify_data.rb
```

This will verify:
- ✅ All candidates have a political organization
- ✅ All candidates have document numbers
- ✅ No duplicate candidates
- ⚠️ Organizations without candidates
- 📊 Candidate distribution by position, status, gender
- 🗺️ Geographic distribution

## Troubleshooting

### "File not found" Error

Make sure the JSON files are in the `data/` directory at the root of the Rails application.

### Validation Errors

If you see validation errors, check:
1. Required fields are present in the JSON
2. Foreign key relationships are valid
3. Data format is correct

### Database Lock Errors (SQLite)

If running seeds concurrently, you might encounter database lock errors. Run seeds sequentially:

```bash
rails runner db/seeds/political_organizations.rb
rails runner db/seeds/candidates.rb
```

## Development

To modify the seed scripts:

1. Edit the appropriate file in `db/seeds/`
2. Test your changes: `rails db:seed`
3. Verify data integrity: `rails runner db/seeds/verify_data.rb`

## Notes

- The seed process takes approximately 10-30 seconds depending on your machine
- SQLite is used by default; performance may vary with other databases
- All dates are stored as strings in the format provided by ONPE
- Photo files are not included; only metadata (GUID and filename) is stored