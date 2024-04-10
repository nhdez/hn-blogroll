class CreateBlogData < ActiveRecord::Migration[7.0]
  def change
    create_table :blog_data do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :rss
      t.string :last_post_title
      t.string :last_post_url
      t.string :last_post_date

      t.timestamps
    end
  end
end
