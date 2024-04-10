require 'nokogiri'
require 'open-uri'
require 'json'
require 'net/http'
require 'uri'

class RefreshDataService
  def call
    url = "https://news.ycombinator.com/item?id=36575081"
    data = fetch_data(url)

    data.each do |record|
      Blog.find_or_create_by(username: record['username']) do |post|
        post.description = record['description']
        post.hyperlink = record['hyperlink']
        post.is_approved = true
      end
    end
  end

  def fetch_data(url)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    parsed_html = Nokogiri::HTML(response)
    data = []
    rows = parsed_html.css('tr.athing.comtr')

    rows.each do |row|
      next if row.at_css('td.ind')['indent'].to_i > 0

      username = row.css('a.hnuser').text
      description = row.css('span.commtext.c00').inner_html
      # sanitize HTML
      description = ActionController::Base.helpers.sanitize(description)
      hyperlink = row.css('a[rel="nofollow noreferrer"]').first['href'] rescue nil

      if hyperlink && description.start_with?(hyperlink)
        description = description[hyperlink.length..]
      end

      if hyperlink
        data << {
          'username' => username,
          'description' => description.strip,
          'hyperlink' => hyperlink
        }
      end
    end

    more_link = parsed_html.at('a.morelink')
    if more_link
      next_url = URI.join(url, more_link['href']).to_s
      data += fetch_data(next_url)
    end

    data
  end
end
