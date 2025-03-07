FactoryBot.define do
  factory :user do
    sequence(:email) { |n| Faker::Internet.unique.email(name: "cubbi_user#{n}") }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthday_date { Faker::Date.birthday(min_age: 18, max_age: 65) }
    location { Faker::Address.time_zone }
  end
end
