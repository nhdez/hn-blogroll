require 'csv'
require 'opml-parser'
include OpmlParser

class MainController < ApplicationController

  def index
    cache_key = "main_index_#{params[:posts]}_#{params[:q]&.to_h}_#{params[:page]}"
    
    if params[:posts].present? && params[:posts] == '1'
      # Show recent posts view
      @q = Post.joins(:blog).where(blogs: { is_approved: true }).ransack(params[:q])
      @posts = @q.result(distinct: true).includes(:blog).recent.page(params[:page]).per(20)
      @view_type = 'posts'
    else
      # Show blogs view
      @q = Blog.approved.ransack(params[:q])
      @blogs = @q.result.includes(:posts).page(params[:page]).per(16).order(username: :asc)
      @view_type = 'blogs'
    end

    respond_to do |format|
      format.html
      format.json do
        Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
          if @view_type == 'posts'
            @posts.as_json(include: { blog: { only: [:id, :username, :hyperlink, :domain] } })
          else
            @blogs.as_json(include: { posts: { only: [:id, :title, :url, :published_at] } })
          end
        end
      end
    end
  end

  def search
    @q = Blog.approved.ransack(params[:q])
    @blogs = @q.result(distinct: true)

    respond_to do |format|
      format.js
    end
  end

  def random_redirect
    blog = Blog.approved.online.order("RANDOM()").first
    blog ||= Blog.approved.order("RANDOM()").first
    
    if blog
      redirect_to blog.hyperlink, allow_other_host: true
    else
      redirect_to root_path, alert: 'No blogs available'
    end
  end

  def download_csv
    @data = Blog.approved.includes(:posts)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['Username', 'HN Karma', 'Description', 'Hyperlink', 'RSS Feed', 'Posts Count', 'Last Post Title', 'Last Post URL', 'Last Post Date', 'Online Status']
      @data.each do |blog|
        latest_post = blog.latest_post
        csv << [
          blog.username, 
          blog.karma, 
          blog.description, 
          blog.hyperlink, 
          blog.rss, 
          blog.posts_count,
          latest_post&.title,
          latest_post&.url,
          latest_post&.published_at,
          blog.is_online ? 'Online' : 'Offline'
        ]
      end
    end

    send_data csv_data, type: 'text/csv', filename: "hn_blogroll_#{Date.current}.csv"
  end

  def download_opml
    blogs = Blog.approved.with_rss

    outlines = blogs.map do |blog|
      feed = {
        text: blog.username || 'N/A',
        title: blog.username || 'N/A',
        type: 'rss',
        xmlUrl: blog.rss,
        htmlUrl: blog.hyperlink
      }
      OpmlParser::Outline.new(feed)
    end

    opml = OpmlParser.export(outlines, 'Hacker News Blogroll OPML Export')
    render xml: opml
  end

  def execute_services
    # Queue background jobs instead of running services directly
    FetchHnDataJob.perform_async
    UpdateBlogPostsJob.perform_async
    UpdateKarmaJob.perform_async
    CheckBlogStatusJob.perform_async
    
    render json: { status: 'success', message: 'Background jobs queued successfully' }
  end
end
