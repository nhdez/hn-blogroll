class AddSubmissionFieldsToBlogs < ActiveRecord::Migration[7.0]
  def change
    add_column :blogs, :submitted_at, :datetime
    add_column :blogs, :rejection_reason, :text
    add_column :blogs, :admin_notes, :text
    add_column :blogs, :submitter_email, :string
    add_column :blogs, :submitter_name, :string
    add_column :blogs, :approval_status, :string, default: 'pending'
    add_column :blogs, :reviewed_at, :datetime
    add_column :blogs, :reviewed_by, :string
    
    add_index :blogs, :approval_status
    add_index :blogs, :submitted_at
  end
end
