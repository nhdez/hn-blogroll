class AddKarmaToBlogData < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :karma, :bigint
  end
end
