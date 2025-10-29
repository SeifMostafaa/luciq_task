class ChatsController < ApplicationController
  before_action :find_application

  def index
    chats = @application.chats.order(:number)
    
    render json: chats, each_serializer: ChatSerializer, status: :ok
  end

  def create
    number = SequenceService.next_chat_number(@application.token)
    job_id = ChatCreationJob.perform_async(@application.id, number)

    render json: { job_id: job_id, number: number }, status: :accepted
  end

  def show
    chat = @application.chats.find_by!(number: params[:number])
    
    render json: chat, serializer: ChatSerializer, status: :ok
  end

  private

  def find_application
    # Use Redis cache for faster lookups
    application_id = CacheService.application_id_by_token(params[:application_token])
    raise ActiveRecord::RecordNotFound, "Application not found" unless application_id
    @application = Application.find(application_id)
  end
end
