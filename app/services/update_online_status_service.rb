require 'net/http'

class UpdateOnlineStatusService
  def call
    Blog.all.each do |blog|
      begin
        response = Net::HTTP.get_response(URI(blog.hyperlink))
        blog.update(is_online: response.is_a?(Net::HTTPSuccess), online_last_check: Time.now)
      rescue StandardError => e
        Rails.logger.error("Error checking online status for blog: #{blog.hyperlink}. Error: #{e.message}")
      end
    end
  end
end
