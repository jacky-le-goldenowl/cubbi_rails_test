puts '~> Create users'

100.times do |_|
  user = FactoryBot.build(:user)
  user.save!
end
