class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table :blogs do |t|
      t.string :username
      t.text :description
      t.string :hyperlink

      t.timestamps
    end
  end
end
