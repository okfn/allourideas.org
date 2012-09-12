class AddFacebookIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :facebook_id, :bigint
    add_index :users, :facebook_id
  end

  def self.down
    remove_column :users, :facebook_id
    remove_index :users, :facebook_id
  end
end
