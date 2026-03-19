class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :choice, null: false, foreign_key: true
      t.text :free_text

      t.timestamps
    end

    add_index :votes, [ :participant_id, :question_id ], unique: true
  end
end
