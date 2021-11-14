require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'
require 'pry-byebug'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You cand find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  clean_number = phone_number.to_s.gsub(/[^\d]/, "")
  if clean_number.length == 11 && clean_number.split('')[0] == 1
    clean_number = clean_number.split('')
    clean_number.shift
    clean_number.join
  elsif clean_number.length == 10
    clean_number
  else
    'No valid phone number'
  end
end

def get_peak_hours(date, hours)
  time = Time.strptime(date, "%Y/%d/%m %k:%M")
  time = time.strftime('%k')
  
  if hours.include?(time)
    hours["#{time}"] += 1
  else
    hours["#{time}"] = 1
  end
end

def get_peak_days(date, days)
  day = Date.strptime(date, "%Y/%d/%m %k:%M").wday

  if days.include?(day.to_s)
    days["#{day}"] += 1
  else
    days["#{day}"] = 1
  end
end

def most_count(hash)
  array = hash.to_a 
  max = ['0', 0]
  array.each_with_index do |key, i|
    if array[i][1] > max[1]
      max = array[i]
    end
  end
  days_of_week = [['Sunday', 0]]
  puts "The most days: #{max}" 
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  '../event_attendees.csv',
  headers: true, 
  header_converters: :symbol
)

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter

hours = {}
peak_day = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  get_peak_hours(row[:regdate], hours)
  get_peak_days(row[:regdate], peak_day)

  # form_letter = erb_template.result(binding
  # save_thank_you_letter(id,form_letter)
end

p most_count(peak_day)
p most_count(hours)

