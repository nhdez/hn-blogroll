class Blog < ApplicationRecord
  has_many :posts, dependent: :destroy
  
  validates :username, :description, :hyperlink, presence: true
  validates :hyperlink, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :username, uniqueness: true
  validates :hyperlink, uniqueness: true
  
  scope :approved, -> { where(is_approved: true) }
  scope :online, -> { where(is_online: true) }
  scope :with_rss, -> { where.not(rss: nil) }
  scope :with_recent_posts, -> { joins(:posts).where('posts.published_at > ?', 1.month.ago).distinct }
  
  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description hyperlink id karma last_post_date last_post_title last_post_url rss updated_at username is_approved is_online]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[posts]
  end
  
  def latest_post
    posts.recent.first
  end
  
  def posts_count
    posts.count
  end
  
  def domain
    URI.parse(hyperlink).host rescue nil
  end
  
  def rss_valid?
    return false unless rss.present?
    
    begin
      uri = URI.parse(rss)
      uri.scheme.present? && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
end
