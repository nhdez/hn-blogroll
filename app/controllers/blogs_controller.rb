class BlogsController < ApplicationRecord
  def create
    @blog = Blog.create(blog_params)
    redirect_to root_path, notice: 'Blog was successfully created.'
  end

  private

  def blog_params
    params.require(:blog).permit(:username, :description, :hyperlink)
  end
end
