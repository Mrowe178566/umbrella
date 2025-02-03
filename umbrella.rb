# -*- encoding: utf-8 -*-
require "http"
require "json"
require "dotenv/load"
require 'ascii_charts'

line_width = 50

puts "=" * line_width
puts "Will you need an Umbrella today?".center(line_width)
puts "=" * line_width
puts
puts "Where are you located?"
user_location = gets.chomp
user_location.capitalize!
puts "Checking the weather for #{user_location}...."

# lat/lng of location from Google Maps API
gmaps_key = ENV.fetch("GMAPS_KEY")
gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_location}&key=#{gmaps_key}"

raw_gmaps_data = HTTP.get(gmaps_url)
parsed_gmaps_data = JSON.parse(raw_gmaps_data)
results_array = parsed_gmaps_data.fetch("results")
first_result_hash = results_array.at(0)
geometry_hash = first_result_hash.fetch("geometry")
location_hash = geometry_hash.fetch("location")
latitude = location_hash.fetch("lat")
longitude = location_hash.fetch("lng")

puts "Your coordinates are #{latitude}, #{longitude}."

# Get the weather from Pirate Weather API
pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
pirate_weather_url = "https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{latitude},#{longitude}"
raw_pirate_weather_data = HTTP.get(pirate_weather_url)
parsed_pirate_weather_data = JSON.parse(raw_pirate_weather_data)
currently_hash = parsed_pirate_weather_data.fetch("currently")
current_temp = currently_hash.fetch("temperature")

puts "It is currently #{current_temp}°F."

# Some locations around the world do not come with minutely data.
minutely_hash = parsed_pirate_weather_data.fetch("minutely", false)
if minutely_hash
  next_hour_summary = minutely_hash.fetch("summary")
  puts "Next hour: #{next_hour_summary}"
end

hourly_hash = parsed_pirate_weather_data.fetch("hourly")
hourly_data_array = hourly_hash.fetch("data")
next_twelve_hours = hourly_data_array[1..12]

precip_prob_threshold = 0.10
any_precipitation = false

# Declare and initialize the data array outside the block
data = []

next_twelve_hours.each_with_index do |hour_hash, index|
  precip_prob = hour_hash.fetch("precipProbability")
  data << [index + 1, (precip_prob * 100).round]

  if precip_prob > precip_prob_threshold
    any_precipitation = true
    precip_time = Time.at(hour_hash.fetch("time"))
    seconds_from_now = precip_time - Time.now
    hours_from_now = seconds_from_now / 60 / 60
    puts "In #{hours_from_now.round} hours, there is a #{(precip_prob * 100).round}% chance of precipitation."
  end
end

if any_precipitation
  puts "You might want to take an umbrella!"
else
  puts "You probably won't need an umbrella."
end
