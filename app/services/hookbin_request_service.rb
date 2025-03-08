require "json"
require "net/http"

class HookbinRequestService < ApplicationService
  def initialize(payload = {})
    @payload = payload
  end

  def call
    uri = URI(ENV["HOOKBIN_URL"])
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = payload.to_json
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end
  end

  private

  attr_reader :payload
end
