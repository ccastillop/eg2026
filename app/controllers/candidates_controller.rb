class CandidatesController < ApplicationController
  def index
    @candidates = Candidate.active
                           .includes(:political_organization, :electoral_district)
                           .order(:position_type, :position_number, :paternal_surname, :maternal_surname, :first_name)
                           .page(params[:page])
                           .per(30)

    # Apply filters if present
    if params[:position_type].present?
      @candidates = @candidates.where(position_type: params[:position_type])
    end

    if params[:political_organization_id].present?
      @candidates = @candidates.where(political_organization_id: params[:political_organization_id])
    end

    if params[:electoral_district_id].present?
      if params[:electoral_district_id] == "nacional"
        # Filter senators without electoral district (national level)
        @candidates = @candidates.where(electoral_district_id: nil)
      else
        @candidates = @candidates.where(electoral_district_id: params[:electoral_district_id])
      end
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @candidates = @candidates.where(
        "first_name LIKE ? OR paternal_surname LIKE ? OR maternal_surname LIKE ? OR document_number LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
  end

  def show
    @candidate = Candidate.includes(:political_organization, :electoral_district)
                         .find(params[:id])
  end
end
