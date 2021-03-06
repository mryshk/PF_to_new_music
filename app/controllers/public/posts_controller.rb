class Public::PostsController < ApplicationController
  # 左メニューバーのマイグループ取得のための定義。以下のアクションの際に使用。
  before_action :set_menu, only: [:show, :index, :search, :search_genre, :search_tag, :order]
  # いいねランキング取得用。以下のアクションの際に使用。
  before_action :fav_rank, only: [:show, :index, :search_tag, :order]
  # 閲覧数ランキング取得用。以下のアクションの際に使用。
  before_action :imp_rank, only: [:index, :search_tag, :order]
  # 本人確認。 自分以外の人をアクセス不可にするための確認
  before_action :ensure_listener, only:[:edit,:update,:destroy]

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    @post.listener_id = current_listener.id
    # 登録のタグを配列(splitメソッド)として取得。
    # Postモデル記載のsave_tagメソッドでsaveする。
    tag_list = params[:post][:tag_name].split(nil)
    if @post.save
      @post.save_tag(tag_list)
      redirect_to home_post_path
    else
      render :new
    end
  end

  def show
    @post = Post.find(params[:id])
    @post_comment_n = PostComment.new
    # 投稿に対するコメント一覧 リプライコメントは除く。
    @comments = PostComment.where(post_id: @post.id, reply_comment: nil)
    # 閲覧数カウント。
    impressionist(@post, nil)
    @post_tags = @post.tags
    @favorite = PostFavorite.find_by(post_id: @post.id, listener_id: current_listener.id)

    # LinkpreviewのKeyを環境変数として使用するための定義。gem/gonを使用。
    gon.linkpreview_key = ENV['LINKPREVIEW_KEY']
    gon.url = @post.post_url
  end

  def index
    @posts = Post.page(params[:page]).includes(:listener).reverse_order
    @tag_list = Tag.all
  end

  def edit
  end

  def update
    @post.listener_id = current_listener.id

    # 登録のタグを配列(splitメソッド)として取得。
    # Postモデル記載のsave_tagメソッドでsaveする。
    tag_list = params[:post][:tag_name].split(nil)
    if @post.update(post_params)
      @post.save_tag(tag_list)
      redirect_to post_path(@post)
    else
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to home_post_path
  end

  def search
    @search = Post.where('post_tweet LIKE ?', "%#{params[:keyword]}%").page(params[:page]).per(5).reverse_order
    # インクリメンタルサーチ(jsonで検索結果取得)があるため、二つの形式を用意。
    respond_to do |format|
      format.html
      format.json
    end
    render "search"
  end

  def search_genre
    @search = Post.where(genre_params).page(params[:page]).per(2).reverse_order
    @keyword = params.permit(:post_genre)
  end

  def search_tag
    # タグをクリックし、タグIDを取得。タグIDが付随する投稿を検索し取得。
    @tag_list = Tag.all
    @tag = Tag.find(params[:tag_id])
    @posts = @tag.posts.page(params[:page]).reverse_order
  end

  def order
    order = params[:keyword]
    # KaminariのPageメソッドがオブジェクトか配列かで記述が変わるため、下記のように条件分岐をしている。
    if (order == "new") || (order == "old")
      @posts = Post.sort(order).page(params[:page])
      # いいねの場合、いいねの多い順で配列されたpost_idを取得する形なので、配列(array)様のKaminariの記述が必要。
    elsif order == "likes"
      @posts = Kaminari.paginate_array(Post.sort(order)).page(params[:page])
    end
  end


  # 以下プライベート
  private

  # 投稿のいいねランキングを取得。
  def fav_rank
    @post_favorite_rank = Post.left_joins(:post_favorites).group(:post_id).order('count(post_id) desc')
  end

   # 投稿の閲覧数ランキングを取得。
  def imp_rank
    @post_impression_rank = Post.all.order(impressions_count: 'DESC').page(params[:page])
  end

  # メニュー用
  # 自分の所属するグループを全て集める。
  def set_menu
    mygroup_ids = current_listener.group_listeners.pluck(:group_id)
    @mygroups = Group.where(id: mygroup_ids)
  end

  # 本人確認 本人以外であれば、ホーム画面へ遷移。
  def ensure_listener
    @post = Post.find(params[:id])
    if @post.listener_id != current_listener.id
      redirect_to home_post_path, alert: '画面を閲覧する権限がありません。'
    end
  end

  #投稿内容取得用のパラメーター
  def post_params
    params.require(:post).permit(:post_url, :post_tweet, :picture, :post_genre)
  end

  #ジャンル取得用のパラメーター
  def genre_params
    params.permit(:post_genre)
  end
end
