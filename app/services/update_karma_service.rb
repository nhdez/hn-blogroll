require 'net/http'

class UpdateKarmaService
  def call
    Blog.all.each do |blog|
      url = "https://hacker-news.firebaseio.com/v0/user/#{blog.username}.json?print=pretty"
      response = Net::HTTP.get(URI(url))
      data = JSON.parse(response)
      if data['karma']
        blog.update(karma: data['karma'])
      else
        Rails.logger.error("No karma found for user: #{blog.username}")
      end
    end
  end
end
