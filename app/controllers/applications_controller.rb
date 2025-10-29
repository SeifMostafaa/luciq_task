class ApplicationsController < ApplicationController

  def show
    # Use Redis cache for faster lookups
    application_id = CacheService.application_id_by_token(params[:token])
    raise ActiveRecord::RecordNotFound, "Application not found" unless application_id
    application = Application.find(application_id)
    render json: application, serializer: ApplicationSerializer, status: :ok
  end

  def create
    application = Application.new(application_params)
    
    if application.save
      # Cache the application ID for faster lookups
      CacheService.cache_application_id(application.token, application.id)
      render json: application, serializer: ApplicationSerializer, status: :created
    else
      render json: { errors: application.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    # Use Redis cache for faster lookups
    application_id = CacheService.application_id_by_token(params[:token])
    raise ActiveRecord::RecordNotFound, "Application not found" unless application_id
    application = Application.find(application_id)
    if application.update(application_params)
      render json: application, serializer: ApplicationSerializer, status: :ok
    else
      render json: { errors: application.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def application_params
    params.require(:application).permit(:name)
  end
end
