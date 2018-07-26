class VideosController < ApplicationController
  load_and_authorize_resource only: [:create]
  layout false
  def show
    @video = Video.find(params[:id])
  end

  def create
    # 浮动窗口上传
    @video = Video.new
    @video.content = params[:file]
    if @video.content.blank?
      render json: { ok: false }, status: 400
      return
    end

    @video.user_id = current_user.id
    if @video.save
      render json: { ok: true, url: video_url(@video.id), type: 'video' }
    else
      render json: { ok: false }
    end
  end
end
