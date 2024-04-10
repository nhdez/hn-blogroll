require 'nokogiri'
require 'open-uri'
require 'json'
require 'net/http'
require 'uri'

class FetchOpmlDataService
  def call
    response = Net::HTTP.get_response(URI.parse('https://gist.githubusercontent.com/Josh-Tucker/030b8cba6557927a27f1c7e6da56a17f/raw/e1c6ff924e3546de43e540f347210bb1f20ba4ee/feeds.opml'))
    data = Nokogiri::XML(response.body)
    outlines = data.xpath('//outline')

    outlines.each do |outline|
      url = outline['text']
      rss = outline['xmlUrl']

      # Check if rss is a relative URL
      unless rss.start_with?('http')
        # Append rss to the base URL
        rss = URI.join(url, rss).to_s
      end

      blog = Blog.find_by_hyperlink(url)
      next unless blog

      blog.update(rss: rss)
    end
  end
end
