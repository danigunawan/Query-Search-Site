class AccountsController < ApplicationController
  def destroy
    if account = (Account.find(params[:id]) rescue nil)
      account.destroy
    end
    redirect_to root_path
  end
end
