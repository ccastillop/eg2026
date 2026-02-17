class PoliticalOrganization < ApplicationRecord
  has_many :candidates, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # Scopes for filtering
  scope :active, -> { where(status: "Inscrito") }
  scope :with_candidates, -> { joins(:candidates).distinct }
  scope :by_type, ->(type) { where(organization_type: type) }
  scope :political_parties, -> { where(organization_type: "Partido Político") }
  scope :alliances, -> { where(organization_type: "Alianza Electoral") }

  def display_name
    acronym.present? ? "#{name} (#{acronym})" : name
  end

  def active?
    status == "Inscrito"
  end
end
