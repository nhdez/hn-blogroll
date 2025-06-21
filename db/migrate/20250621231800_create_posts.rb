class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url, null: false
      t.text :content
      t.text :summary
      t.datetime :published_at
      t.string :guid
      t.string :unique_key, null: false
      t.integer :word_count
      t.string :author
      t.json :tags, default: []

      t.timestamps
    end
    
    add_index :posts, :unique_key, unique: true
    add_index :posts, :published_at
    add_index :posts, [:blog_id, :published_at]
  end
end
