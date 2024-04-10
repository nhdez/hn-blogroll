require 'csv'
require 'opml-parser'
include OpmlParser

class MainController < ApplicationController

  def index
    if params[:posts].present? && params[:posts] == '1'
      @q =  Blog.where(is_approved: true).where.not(last_post_title: nil).ransack(params[:q])
      @blogs = @q.result.page(params[:page]).order(Arel.sql("COALESCE(last_post_date, '#{2.weeks.ago.to_s(:db)}') desc"))
    else
      @q = Blog.where(is_approved: true).ransack(params[:q])
      @blogs = @q.result.page(params[:page]).per(16).order(username: :asc)
    end

    respond_to do |format|
      format.html
      format.json { render json: @blogs }
    end
  end

  def search
    @q = Blog.ransack(params[:q])
    @blogs = @q.result(distinct: true)

    respond_to do |format|
      format.js
    end
  end

  def random_redirect
    record = Blog.order("RANDOM()").first
    redirect_to record.hyperlink, allow_other_host: true
  end

  def download_csv
    @data = Blog.all

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['Username', 'HN Karma', 'Description', 'Hyperlink', 'RSS Feed', 'Last Post Title', 'Last Post URL', 'Last Post Date']
      @data.each do |blog|
        csv << [blog.username, blog.karma, blog.description, blog.hyperlink, blog.rss, blog.last_post_title, blog.last_post_url, blog.last_post_date]
      end
    end

    send_data csv_data, type: 'text/csv', filename: 'blogroll_data.csv'
  end

  def download_opml
    blogs = Blog.where.not(last_post_title: nil)

    outlines = blogs.map do |blog|
      feed = {
        text: blog.username || 'N/A',
        title: blog.username || 'N/A',
        type: 'rss',
        xmlUrl: blog.rss,
        htmlUrl: blog.rss
      }
      OpmlParser::Outline.new(feed)
    end

    opml = OpmlParser.export(outlines, 'Hacker News Blogroll OPML Export')
    render xml: opml
  end

  def execute_services
    RefreshDataService.new.call
    FetchOpmlDataService.new.call
    FetchLatestPostsService.new.call
    UpdateKarmaService.new.call
  end
end
