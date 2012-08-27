class ChoiceChoices < ActiveRecord::Migration
  def self.up
    create_table :choice_choices do |t|
      t.integer :choice_id, :null => false
      t.integer :related_choice_id
    end

    add_index :choice_choices, :choice_id, :unique => true
    add_index :choice_choices, :related_choice_id
    add_index :choice_choices, [:choice_id, :related_choice_id], :unique => true
  end

  def self.down
    drop_table :choice_choices
  end
end
