class MigrateSecondaryTableIntoBlogs < ActiveRecord::Migration[7.0]
  def up
    # Step 1: Add the new columns to the blogs table
    add_column :blogs, :rss, :string
    add_column :blogs, :last_post_title, :string
    add_column :blogs, :last_post_url, :string
    add_column :blogs, :last_post_date, :string

    # Step 2: Copy the data from the blog_data table to the blogs table
    execute <<-SQL
      UPDATE blogs
      SET rss = blog_data.rss,
          last_post_title = blog_data.last_post_title,
          last_post_url = blog_data.last_post_url,
          last_post_date = blog_data.last_post_date
      FROM blog_data
      WHERE blogs.id = blog_data.blog_id
    SQL

    # Step 3: Remove the blog_data table
    drop_table :blog_data
  end
end
