class Account < ApplicationRecord
  serialize :graph_data

  def self.create_new_account(auth)
    self.find_or_create_by(nickname: auth['info']['nickname']) do |user|
      user.name = auth['info']['name']
      user.nickname = auth['info']['nickname']
      user.token = auth['credentials']['token']
      user.token_secret = auth['credentials']['secret']
    end
  end
end
