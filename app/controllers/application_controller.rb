class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found(exception)
    render json: { error: "#{exception.model.constantize.model_name.human} not found" }, status: :not_found
  end
end
