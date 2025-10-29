class ApplicationSerializer < ActiveModel::Serializer
  attributes :token, :name, :chats_count, :created_at
end
