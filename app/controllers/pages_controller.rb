class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
  end

  def terms
  end

  def privacy
  end

  def cookies
  end
end
