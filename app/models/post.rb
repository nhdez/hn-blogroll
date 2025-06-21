class Post < ApplicationRecord
  belongs_to :blog
  
  validates :title, :url, :unique_key, presence: true
  validates :unique_key, uniqueness: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  
  scope :recent, -> { order(published_at: :desc) }
  scope :by_blog, ->(blog_id) { where(blog_id: blog_id) }
  scope :published_after, ->(date) { where('published_at > ?', date) }
  
  before_save :calculate_word_count
  before_save :generate_summary
  
  def self.ransackable_attributes(auth_object = nil)
    %w[title content summary author published_at tags word_count]
  end
  
  def self.ransackable_associations(auth_object = nil)
    %w[blog]
  end
  
  private
  
  def calculate_word_count
    return unless content.present?
    self.word_count = content.split.size
  end
  
  def generate_summary
    return unless content.present?
    return if summary.present?
    
    # Simple summary generation - first 200 characters
    stripped_content = ActionController::Base.helpers.strip_tags(content)
    self.summary = stripped_content.truncate(200)
  end
end
