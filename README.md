# Cubbi Test

Cubbi Test is a Ruby on Rails application designed to send personalized happy birthday messages to users at exactly 9 AM in their local time zone. Whether a user is in New York, Melbourne, or anywhere in the world, they will receive the message “Hey, {full_name} it’s your birthday” right on time.

## Features

- **User Management API:**
  - **POST /user:** Create a new user.
  - **DELETE /user:** Delete an existing user.
- **User Attributes:**
  Each user record includes a first name, last name, birthday date, and location (the location format is flexible).
- **Timezone-Aware Scheduling:**
  The system schedules a birthday message to be sent at 9 AM based on each user’s local time.
- **Reliable Message Delivery:**
  In the event of downtime (e.g., the service being unavailable for a day), the system is capable of recovering and sending any unsent birthday messages.
- **Extensible Architecture:**
  Designed with a high level of abstraction so that future features (like sending happy anniversary messages) can be added with minimal changes.
- **Background Job Processing:**
  Utilizes Sidekiq for processing jobs asynchronously to handle message scheduling and delivery.
- **Seed Data Management:**
  Uses the Seedbank gem for managing seed data.

## Technologies Used

- **Ruby on Rails 8.0.1:** Main framework for building the application.
- **Sidekiq:** For managing background job processing.
- **Seedbank:** For seed data management.
- **Database:** You may choose your preferred database (e.g., PostgreSQL, SQLite, etc.).

## Installation and Setup

1. **Clone the Repository:**

```bash
 git clone git@github.com:jacky-le-goldenowl/cubbi_rails_test.git
 cd cubbi_rails_test
```

2. **Install Dependencies:**

```bash

bundle install
```

3. **Database Setup:**

Configure your database settings in config/database.yml.

Create and migrate the database:

```bash

rails db:create
rails db:migrate
```

Seed the Database:

This project uses the Seedbank gem to manage seed data.

To run the seeds, execute:

```bash

bundle exec rake db:seed:all
```

4. **Start the Rails Server:**

```bash

rails server
```

5. **Start Sidekiq:**

In a separate terminal run:

```bash

bundle exec sidekiq
```

## API Endpoints

- POST /user
  - Description: Creates a new user.
  - Required Parameters:
    first_name (String)
    last_name (String)
    birthday (Date; format as needed)
    location (String; TimeZone location)
- DELETE /user
  Description: Deletes an existing user.

## Birthday Message Scheduling

Message Format:

The message sent is:

Hey, {full_name} it’s your birthday
Delivery:

At 9 AM on each user’s birthday (based on their local time), the system triggers a call to a Hookbin endpoint (e.g., one created at hookbin.com) to send the message.
