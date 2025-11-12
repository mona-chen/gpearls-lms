module Current
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
  end

  def set_current_user
    Current.user = current_user
  end

  module ClassMethods
    def current_user
      Current.user
    end
  end

  class << self
    attr_accessor :user
  end
end
