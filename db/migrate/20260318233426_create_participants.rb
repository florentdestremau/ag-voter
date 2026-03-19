class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :ag_session, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token, null: false

      t.timestamps
    end

    add_index :participants, :token, unique: true
  end
end
