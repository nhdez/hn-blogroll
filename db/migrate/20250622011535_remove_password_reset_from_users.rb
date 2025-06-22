class RemovePasswordResetFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token)
  end
end
