puts '~> Create users'

10.times do |_|
  user = FactoryBot.build(:user)
  user.save!
end
