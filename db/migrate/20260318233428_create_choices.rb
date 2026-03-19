class CreateChoices < ActiveRecord::Migration[8.1]
  def change
    create_table :choices do |t|
      t.references :question, null: false, foreign_key: true
      t.string :text, null: false
      t.boolean :is_other, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
