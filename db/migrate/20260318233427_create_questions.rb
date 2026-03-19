class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.references :ag_session, null: false, foreign_key: true
      t.string :text, null: false
      t.string :status, null: false, default: "pending"
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
