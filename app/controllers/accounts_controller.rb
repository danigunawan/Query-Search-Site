class AccountsController < ApplicationController
  def destroy
    session[:graph_data] = nil
    if account = (Account.find(params[:id]) rescue nil)
      account.destroy
    end
    redirect_to root_path
  end
end
