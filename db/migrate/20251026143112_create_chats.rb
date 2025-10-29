class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.integer :number, null: false
      t.references :application, null: false, foreign_key: true, index: true
      t.integer :messages_count, default: 0, null: false

      t.timestamps
    end
    add_index :chats, [:application_id, :number], unique: true
  end
end
