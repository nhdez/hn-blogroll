class AddApprovedToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :is_approved, :boolean, default: false
  end
end
