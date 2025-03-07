require "json"
require "net/http"

class HookbinRequestService < ApplicationService
  def self.send_post_request(payload = {})
    uri = URI(ENV["HOOKBIN_URL"])
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = payload.to_json
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end
  end
end
