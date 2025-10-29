class MessagesController < ApplicationController
  before_action :find_chat

  def index
    messages = @chat.messages.order(:number)

    render json: messages, each_serializer: MessageSerializer, status: :ok
  end

  def show
    message = @chat.messages.find_by!(number: params[:number])
    
    render json: message, serializer: MessageSerializer, status: :ok
  end

  def create
    number = SequenceService.next_message_number(params[:application_token], params[:chat_number])
    job_id = MessageCreationJob.perform_async(@chat.id, params[:message][:body], number)

    render json: { job_id: job_id, number: number }, status: :accepted
  end

  def update
    message = @chat.messages.find_by!(number: params[:number])
    if message.update(params.require(:message).permit(:body))
      render json: message, serializer: MessageSerializer, status: :ok
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def search
    return render json: { error: "Search query is required" }, status: :bad_request if params[:q].blank?

    results = Message.search(
      params[:q],
      where: { chat_id: @chat.id },
      fields: [:body],
      match: :word_start,
      load: true
    )
    
    render json: results, each_serializer: MessageSerializer, status: :ok
  rescue Searchkick::ImportError, Faraday::ConnectionFailed => e
    Rails.logger.error "Search service unavailable: #{e.message}"
    render json: { error: "Search service unavailable", details: e.message }, status: :service_unavailable
  rescue StandardError => e
    Rails.logger.error "Search failed: #{e.class} - #{e.message}"
    render json: { error: "Search failed", details: e.message }, status: :internal_server_error
  end

  private

  def find_chat
    # Use Redis cache for faster lookups - single query instead of two
    chat_id = CacheService.chat_id_by_token_and_number(params[:application_token], params[:chat_number])
    raise ActiveRecord::RecordNotFound, "Chat not found" unless chat_id
    @chat = Chat.find(chat_id)
  end
end
