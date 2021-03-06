class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception # ActionController::InvalidAuthenticityTokenエラー対策

  # before_action :authenticate_listener!, except: [:top, :about]
  before_action :configure_permitted_parameters, if: :devise_controller?

  # 権限確認（cancancan）
  def current_ability
    @current_ability ||= ::Ability.new(current_listener)
  end
  # 権限確認後の遷移先（権限無しの場合）
  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to home_post_path, alert: '画面を閲覧する権限がありません。'
  end

  def after_sign_in_path_for(resource)
    if listener_signed_in? # リスナー側ログイン後
      home_post_path # リスナー側トップ画面に遷移
    else
      admin_root_path
    end
  end

  def after_sign_out_path_for(resource) # リスナー側ログアウト後
    root_path # TOP画面に遷移
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :name])
  end
end
