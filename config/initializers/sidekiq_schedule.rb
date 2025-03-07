require "sidekiq"
require "sidekiq-scheduler"
require "yaml"

schedule_file = Rails.root.join("config", "scheduler.yml")

if File.exist?(schedule_file) && Sidekiq.server?
  Sidekiq.schedule = YAML.load_file(schedule_file)
  Sidekiq::Scheduler.reload_schedule!
  Rails.logger.info "Loaded Sidekiq schedule from #{schedule_file}"
else
  Rails.logger.info "No Sidekiq schedule file found at #{schedule_file}"
end
