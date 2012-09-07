class CreateConsultation < ActiveRecord::Migration
  def self.up
    create_table :consultations do |t|
      t.string :name, :null => false
      t.boolean :active, :null => false, :default => false
      t.references :user
      t.timestamps
    end

    add_column :earls, :consultation_id, :integer
    add_index :earls, :consultation_id
  end

  def self.down
    remove_column :earls, :consultation_id
    drop_table :consultations
  end
end
