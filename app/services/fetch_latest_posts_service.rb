require 'open-uri'
require 'json'
require 'net/http'
require 'uri'

class FetchLatestPostsService

  def call
    Blog.all.each do |blog|
      next unless blog.rss

      begin
        latest_post = fetch_latest_post(blog.rss)
        next unless latest_post

        blog.update(
          last_post_title: latest_post[:title],
          last_post_url: latest_post[:url],
          last_post_date: latest_post[:published]
        )
      rescue StandardError => e
        Rails.logger.error("Error updating latest post for blog: #{blog.id}. Error: #{e.message}")
        next
      end
    end
  end

  def fetch_latest_post(feed_url)
    uri = URI(feed_url)
    xml = Net::HTTP.get(uri)
    feed = Feedjira.parse(xml)
    latest_entry = feed.entries.first

    if latest_entry
      {
        title: latest_entry.title,
        url: latest_entry.url,
        published: latest_entry.published
      }
    else
      nil
    end
  end
end
