class Video < ApplicationRecord
  belongs_to :user, optional: true

  validates_presence_of :content

  # 封面图
  mount_uploader :content, PhotoUploader
end
