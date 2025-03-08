# Cubbi Test

Cubbi Test is a Ruby on Rails application designed to send personalized happy birthday messages to users at exactly 9 AM in their local time zone. Whether a user is in New York, Melbourne, or anywhere in the world, they will receive the message “Hey, {full_name} it’s your birthday” right on time.

**Table of Contents**

- [Cubbi Test](#cubbi-test)
  - [Features](#features)
  - [Overview](#overview)
  - [Technologies Used](#technologies-used)
  - [Installation and Setup](#installation-and-setup)
  - [API Endpoints](#api-endpoints)
  - [Birthday Message Scheduling](#birthday-message-scheduling)
  - [Screenshots:](#screenshots)

---

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

## Overview

- **Rails & Sidekiq**

  - Built on Rails with Sidekiq for background job processing.

- **API Endpoints**

  - Provides simple endpoints for creating and deleting users.

- **User Model**

  - **Attributes:** first name, last name, birthday date, email, and location.
  - **Validations:** unique email, valid email format, presence of birthday date.
  - **Callback:** triggers update of birthday notifications when `birthday_date` is updated.

- **BirthdayNotification Model**

  - **Association:** belongs to a User.
  - **Unique Constraint:** one notification per user per birthday (unique on `user_id` & `birthday`).
  - **Enum Status:** scheduled, sent, failed, cancelled.
  - **Tracking:** includes a `retry_count` with a maximum defined by `MAX_RETRIES`.
  - **Constants:**
    - `MAX_RETRIES`
    - `NOTIFICATION_TIME`

- **Service Objects**

  - **ScheduleTodayNotificationService**
    - Scans all users to check if today (in the user's local time) is their birthday.
    - Creates or finds a BirthdayNotification.
    - Enqueues a job to send the notification at 9 AM local time.
  - **UpdateBirthdayNotificationService**
    - Called via a callback when a user's `birthday_date` is updated.
    - Cancels outdated notifications (updates status to cancelled) if the birthday changes.
    - Optionally, enqueues a new job if needed.
  - **UserTimeHelper Module**
    - Provides shared time-related helper methods (e.g., `today_local`, `scheduled_time`, `user_timezone`, `birthday_today?`).
    - Included in service objects to centralize timezone and scheduling logic.

- **Background Jobs**

  - **SendBirthdayNotificationJob**

    - Responsible for sending the actual birthday notification (via Hookbin webhook API).

  - **SendScheduledBirthdayNotificationsJob**

    - Periodically re-enqueues pending notifications based on database data.
    - Acts as a safeguard in case Redis (which stores jobs) loses data.
    - Although the possibility is low, it ensures that the persistent database records can recover and re-schedule any lost notifications.

  - **Job Scheduling**
    - Uses sidekiq-cronjob for periodic jobs:
      - Scanning for birthdays of user
      - Optionally, retrying jobs if necessary (leveraging Sidekiq's built-in retry mechanism).

- **Job Resilience**

  - The dedicated re-enqueue job (`SendScheduledBirthdayNotificationsJob`) ensures data reliability.
  - In the rare event of Redis data loss, persistent database records allow recovery of pending notifications.

- **Testing**
  - Uses RSpec for unit and integration tests.
  - Model tests for validations, associations, and callbacks.
  - Service tests for scheduling and updating notifications.
  - Define factories

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

## Screenshots:

- Sidekiq:
  ![Sidekiq](docs/sidekiq_cubbi.png)
- Rubocop linter
  ![Rubocop](docs/rubocop.png)
- Coverage:
  ![Coverage](docs/coverage.png)
