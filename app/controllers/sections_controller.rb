class SectionsController < ApplicationController
  include Topics::ListActions

  def show
    @section = Section.find(params[:id])
    @suggest_topics = []
    if params[:page].to_i <= 1
      @suggest_topics = topics_scope.by_section_ids(@section.id).suggest.limit(3)
    end

    @topics = topics_scope.by_section_ids(@section.id).without_suggest.last_actived.page(params[:page])
    @page_title = t("menu.topics")
    @read_topic_ids = []
    if current_user
      @read_topic_ids = current_user.filter_readed_topics(@topics + @suggest_topics)
    end
    render "/topics/index"
  end
end
