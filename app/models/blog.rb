class Blog < ApplicationRecord
  validates :username, :description, :hyperlink, presence: true
  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description hyperlink id karma last_post_date last_post_title last_post_url rss updated_at username]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
