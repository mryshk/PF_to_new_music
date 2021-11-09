class Public::HomesController < ApplicationController
  # before_action :post_join


  def top
  end

  def home
    # フォローしている人のみを表示。タイムライン機能。
    following_repost_ids = Repost.select(:post_id).where(listener_id: [current_listener, *current_listener.following_ids])
    # following_ids = Relationship.select(followed_id).where(follower_id: current_listener.id)
    @post_repost = Post.joins("LEFT OUTER JOIN reposts ON post.id = reposts.post_id AND (reposts.listener_id = #{current_listener.id} OR reposts.listener_id IN (SELECT followed_id FROM relationships WHERE follower_id = #{current_listener.id}))").select("posts.*,reposts.listener_id , (SELECT name FROM listeners WHERE id = reposts.listener_id) AS repost_listener_name")

    @posts = Post.where(id: following_repost_ids).or(Post.where(listener_id: [current_listener, *current_listener.following_ids])).page(params[:page]).includes(:listener).per(10).reverse_order
    # @posts = Post.where(listener_id: [current_listener, *current_listener.following_ids]).page(params[:page]).includes(:listener).per(2).reverse_order
    @posts.each do |post|
      @repost = Repost.includes(:listener).find_by(post_id: post.id)
    end
    @post_favorite_rank = Post.includes(:favo_users).sort { |a, b| b.favo_users.size <=> a.favo_users.size }
    @post_impression_rank = Post.all.order(impressions_count: 'DESC').page(params[:page])
    # メニュー用
    # 自分の所属するグループを全て集める。
    mygroup_ids = current_listener.group_listeners.pluck(:group_id)
    @mygroups = Group.where(id: mygroup_ids)
     binding.pry
  end

  # def post_join
  #
  # end
end
