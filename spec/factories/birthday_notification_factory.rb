FactoryBot.define do
  factory :birthday_notification do
    status { BirthdayNotification.statuses.sample }
    birthday { Faker::Date.birthday(min_age: 18, max_age: 65) }
    retry_count { rand(0..3) }

    association :user
  end
end
