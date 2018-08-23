class CheckinController < ApplicationController
  before_action :authenticate_user!

  def index
    current_user.check_in!
    redirect_back_or_default(root_url)
  end
end
