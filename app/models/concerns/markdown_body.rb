# frozen_string_literal: true

# 转换 body -> html
# [Plugin API]
module MarkdownBody
  extend ActiveSupport::Concern
  include ActionView::Helpers::OutputSafetyHelper
  include ApplicationHelper
  included do
    before_save :sanitize_images
  end

  def body_html
    markdown(body)
  end

  private
    def sanitize_images
      self.body = body.split(/\)[\s|\r\n]*!\[\]\(/).join(")![](").gsub('\r\n', '\r\n\r\n')
    end
end
