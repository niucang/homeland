class VideosController < ApplicationController
  # load_and_authorize_resource
  layout false
  def show
    p '#' * 99
  end

  def create
    # 浮动窗口上传
    @video = Video.new
    @video.image = params[:file]
    if @video.image.blank?
      render json: { ok: false }, status: 400
      return
    end

    @video.user_id = current_user.id
    if @video.save
      render json: { ok: true, url: @video.image.url(:large) }
    else
      render json: { ok: false }
    end
  end
end
