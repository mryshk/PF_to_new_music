class Public::HomesController < ApplicationController
  # フォローしている人のみを表示。タイムライン機能。

  def top
    # @Posts = Post.where(listener_id:[current_listener,*current_listener.following_ids]).page(params[:page]).reverse_order
  end

  def about
  end
end
