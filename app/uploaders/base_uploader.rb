# frozen_string_literal: true

class BaseUploader < CarrierWave::Uploader::Base
  # 在 UpYun 或其他平台配置图片缩略图
  # http://docs.upyun.com/guide/#_12
  # Avatar
  # 固定宽度和高度
  # xs - 32x32
  # sm - 48x48
  # md - 96x96
  # lg - 192x192
  #
  # Photo
  # large - 1920x? - 限定宽度，高度自适应
  #
  storage :qiniu
  ALLOW_VERSIONS = %w[xs sm md lg large]

  def store_dir
    dir = model.class.to_s.underscore
    if Setting.upload_provider == "file"
      dir = "uploads/#{dir}"
    end
    dir
  end

  def extension_white_list
    %w[jpg jpeg gif png svg mp4]
  end

  def url(version_name = nil)
    @url ||= super({})
    return @url if version_name.blank?
    version_name = version_name.to_s
    unless version_name.in?(ALLOW_VERSIONS)
      raise "ImageUploader version_name:#{version_name} not allow."
    end

    case Setting.upload_provider
    when "aliyun"
      super(thumb: "?x-oss-process=image/#{aliyun_thumb_key(version_name)}")
    when "upyun"
      [@url, version_name].join("!")
    else
      [@url, "imageView2/1/w/#{qiniuyun_thumb_key(version_name)}"].join("?")
    end
  end

  private

    def aliyun_thumb_key(version_name)
      case version_name
      when "large" then "resize,w_1920"
      when "lg"    then "resize,w_192,h_192,m_fill"
      when "md"    then "resize,w_96,h_96,m_fill"
      when "sm"    then "resize,w_48,h_48,m_fill"
      when "xs"    then "resize,w_32,h_32,m_fill"
      else
        "resize,w_32,h_32,m_fill"
      end
    end

    def qiniuyun_thumb_key(version_name)
      case version_name
      when "large" then "1920"
      when "lg"    then "192/h/192"
      when "md"    then "96/h/96"
      when "sm"    then "48/h/48"
      when "xs"    then "32/h/32"
      else
        "32/h/32"
      end
    end
end
