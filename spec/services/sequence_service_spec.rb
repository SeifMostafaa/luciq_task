require 'rails_helper'

RSpec.describe SequenceService do
  before { $redis.flushdb }

  describe '.next_chat_number' do
    let(:application) { create(:application) }

    it 'returns 1 for first call' do
      number = SequenceService.next_chat_number(application.token)
      expect(number).to eq(1)
    end

    it 'returns sequential numbers' do
      num1 = SequenceService.next_chat_number(application.token)
      num2 = SequenceService.next_chat_number(application.token)
      num3 = SequenceService.next_chat_number(application.token)
      
      expect(num1).to eq(1)
      expect(num2).to eq(2)
      expect(num3).to eq(3)
    end

    it 'backfills from database if Redis key is missing' do
      create(:chat, application: application, number: 5)
      
      # Simulate Redis restart
      $redis.flushdb
      
      number = SequenceService.next_chat_number(application.token)
      expect(number).to eq(6)
    end

    it 'handles concurrent calls atomically' do
      threads = 10.times.map do
        Thread.new { SequenceService.next_chat_number(application.token) }
      end
      
      numbers = threads.map(&:value)
      
      # All numbers should be unique
      expect(numbers.uniq.length).to eq(10)
      # Numbers should be sequential
      expect(numbers.sort).to eq((1..10).to_a)
    end
  end

  describe '.next_message_number' do
    let(:application) { create(:application) }
    let(:chat) { create(:chat, application: application, number: 1) }

    it 'returns 1 for first call' do
      number = SequenceService.next_message_number(application.token, chat.number)
      expect(number).to eq(1)
    end

    it 'returns sequential numbers' do
      num1 = SequenceService.next_message_number(application.token, chat.number)
      num2 = SequenceService.next_message_number(application.token, chat.number)
      num3 = SequenceService.next_message_number(application.token, chat.number)
      
      expect(num1).to eq(1)
      expect(num2).to eq(2)
      expect(num3).to eq(3)
    end

    it 'backfills from database if Redis key is missing' do
      create(:message, chat: chat, number: 7)
      
      # Simulate Redis restart
      $redis.flushdb
      
      number = SequenceService.next_message_number(application.token, chat.number)
      expect(number).to eq(8)
    end

    it 'maintains separate sequences per chat' do
      chat2 = create(:chat, application: application, number: 2)
      
      num1 = SequenceService.next_message_number(application.token, chat.number)
      num2 = SequenceService.next_message_number(application.token, chat2.number)
      
      expect(num1).to eq(1)
      expect(num2).to eq(1)
    end
  end
end

