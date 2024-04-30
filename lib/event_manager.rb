require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(_zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: _zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  clean_number = phone_number.gsub(/[^\d]/, '')

  if clean_number.length < 10
    'Bad Number'
  elsif clean_number.length == 11 && clean_number[0] == 1
    clean_number[1..10]
  elsif clean_number.length == 11 && clean_number[0] != 1
    'Bad Number'
  elsif clean_number.length > 11
    'Bad Number'
  else
    clean_number
  end
end

def extract_registration_hours(registration_date)
  date_formated = DateTime.strptime(registration_date, '%D %H:%M')

  date_formated.hour
end

def extract_registration_days(registration_day)
  date_formated = DateTime.strptime(registration_day, '%D %H:%M')
  Date::DAYNAMES[date_formated.wday]
end

def peak_registration_hours(hours_array)
  counted_hours = hours_array.tally
  peak_hours = counted_hours.sort_by { |_key, value| value }.reverse
  puts peak_hours.first(2).to_h
end

def peak_registration_days(days_array)
  counted_days = days_array.tally
  peak_days = counted_days.sort_by { |_key, value| value }.reverse
  puts peak_days.first(3).to_h
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

registration_hours = []
registration_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  registration_date = extract_registration_hours(row[:regdate])
  registration_hours.push(registration_date)

  registration_day = extract_registration_days(row[:regdate])
  registration_days.push(registration_day)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
end

peak_registration_hours(registration_hours)
peak_registration_days(registration_days)
