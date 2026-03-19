class AddClaimedAtToParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :claimed_at, :datetime
  end
end
