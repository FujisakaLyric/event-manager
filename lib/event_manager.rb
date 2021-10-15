puts 'Event Manager Initialized!'

# # Read File Contents
# contents = File.read("event_attendees.csv")

# # Read File Line by Line
# lines = File.readlines("event_attendees.csv")

# lines.each_with_index do |line, row_index|
#     next if row_index == 0
#     columns = line.split(",")
#     name = columns[2]
# end

# Parsing using CSV Library and Google API Client
# Using an ERB Template
def clean_zipcode(zipcode)
    if zipcode.nil?
        "00000"
    elsif zipcode.length < 5
        zipcode.rjust(5, "0")
    elsif zipcode.length > 5
        zipcode[0..4]
    else 
        zipcode
    end
    # One line code -> zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(number)
  number = number.gsub(/[^0-9]/, "")
  if (number.length == 10)
    number
  elsif (number.length == 11)
    if (number[0] == "1")
      number[1..10]
    else
      "Invalid"
    end
  else
    "Invalid"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")
  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def time_targetting(reg_date)
  time = Time.strptime(reg_date, "%m/%d/%y %k:%M")
  time.hour
end

def day_targetting(reg_date)
  day = Date.strptime(reg_date, "%m/%d/%y %k:%M")
  day.wday
end

def print_peak(time_array, date_array)
  peak_times = time_array.each_with_object([]).with_index do |(time, arr), index| 
    arr << index if time == time_array.max
  end
  
  peak_times.map! { |time| time = time.to_s << ":00" }
  puts "These are the peak times: #{peak_times}"

  peak_days = date_array.each_with_object([]).with_index do |(day, arr), index| 
    arr << index if day == date_array.max
  end
  
  peak_days.map!.with_index { |day, index| day = Date::DAYNAMES[index] }
  puts "These are the peak days: #{peak_days}"
end

require "csv"
require "google/apis/civicinfo_v2"
require 'erb'
require 'time'
require 'date'

parsed_contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)
template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter
reg_time = Array.new(24, 0)
reg_date = Array.new(7, 0)

parsed_contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  reg_time[time_targetting(row[:regdate])] += 1
  reg_date[day_targetting(row[:regdate])] += 1
  legislators = legislators_by_zipcode(zipcode)

  personal_letter = erb_template.result(binding)
  save_thank_you_letter(id, personal_letter)
end

print_peak(reg_time, reg_date)