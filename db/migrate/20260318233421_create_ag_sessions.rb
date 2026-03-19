class CreateAgSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :ag_sessions do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :ag_sessions, :token, unique: true
  end
end
