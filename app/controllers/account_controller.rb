# frozen_string_literal: true

# Devise User Controller
class AccountController < Devise::RegistrationsController
  before_action :require_no_sso!, only: %i[new create]

  def new
    super
  end

  def edit
    redirect_to setting_path
  end

  # POST /resource
  def create
    build_resource(sign_up_params)
    resource.login = params[resource_name][:login]
    resource.email = params[resource_name][:email]
    if verify_rucaptcha?(resource) && resource.save
      sign_in(resource_name, resource)
    end
  end

  def sign_up_with_mobile
    new
  end

  def create_with_mobile
    build_resource(sign_up_params)
    resource.login = params[resource_name][:login]
    resource.mobile_phone = params[resource_name][:mobile_phone]
    resource.init_email
    if verify_message_code(resource) && resource.save
      sign_in(resource_name, resource)
    end
    render 'create'
  end

  def get_msg_code
    ::MsgCodeService.send_code_and_cache_sms(params[:mobile_phone])
  end

  private

    # Overwrite the default url to be used after updating a resource.
    # It should be edit_user_registration_path
    # Note: resource param can't miss, because it's the super caller way.
    def after_update_path_for(_)
      edit_user_registration_path
    end

    def verify_message_code(resource)
      return true if Rails.env.development? && params[:verify_message_code] == '8888'
      if MsgCodeService.verify_message_code(resource.mobile_phone, params[:verify_message_code])
        resource.errors.add(:base, "验证码错误")
        return false
      end
      true
    end
end
