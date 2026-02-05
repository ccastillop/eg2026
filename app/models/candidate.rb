class Candidate < ApplicationRecord
  belongs_to :political_organization
  belongs_to :electoral_district, optional: true

  validates :document_number, presence: true
  validates :position_type, presence: true

  # Scopes for filtering
  scope :presidents, -> { where(position_type: "PRESIDENTE DE LA REPÚBLICA") }
  scope :vice_presidents, -> { where(position_type: ["PRIMER VICEPRESIDENTE DE LA REPÚBLICA", "SEGUNDO VICEPRESIDENTE DE LA REPÚBLICA"]) }
  scope :deputies, -> { where(position_type: "DIPUTADO") }
  scope :senators, -> { where(position_type: "SENADOR") }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_electoral_district, ->(district_id) { where(electoral_district_id: district_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :active, -> { where(status: ["INSCRITO", "ADMITIDO"]) }

  def full_name
    [first_name, paternal_surname, maternal_surname].compact.join(" ")
  end

  def is_presidential_candidate?
    position_type == "PRESIDENTE DE LA REPÚBLICA"
  end

  def is_vice_president_candidate?
    position_type.include?("VICEPRESIDENTE")
  end

  def is_deputy_candidate?
    position_type == "DIPUTADO"
  end

  def is_senator_candidate?
    position_type == "SENADOR"
  end

  def photo_url
    return nil unless photo_guid.present?
    # This could be adjusted based on where photos are stored
    "/photos/#{photo_guid}.jpg"
  end
end
