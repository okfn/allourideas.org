class UsersController < Clearance::UsersController
  def create
    @user = User.new(params[:user])

    if @user.save
      sign_in(@user)
      redirect_to params[:callback] || root_url
    else
      render :new
    end
  end
end
