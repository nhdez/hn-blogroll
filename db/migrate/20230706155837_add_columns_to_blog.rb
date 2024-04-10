class AddColumnsToBlog < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :is_online, :boolean
    add_column :blogs, :online_last_check, :datetime
  end
end
