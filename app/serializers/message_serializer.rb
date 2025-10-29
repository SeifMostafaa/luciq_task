class MessageSerializer < ActiveModel::Serializer
  attributes :number, :body, :created_at
end
