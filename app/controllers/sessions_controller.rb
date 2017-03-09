class SessionsController < ApplicationController
  def create
    auth = request.env['omniauth.auth']
    curr_account = Account.create_new_account(auth)
    session['account_id'] = curr_account.id
    redirect_to root_path
  end

  def terminate_account
    destroy_account
    redirect_to root_path
  end

  def select_account
    if account = Account.find(params[:id])
      session['account_id'] = account.id
    end
    redirect_to root_path
  end
end
