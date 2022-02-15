require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[-().+E ]/, '')
  if phone_number.length == 10
    puts "Phone number: #{phone_number}"
  elsif phone_number.length == 11 && phone_number[0] == 1
    puts "Phone number: #{phone_number += phone_number[1, 10]}"
  elsif phone_number.length > 11 || phone_number.length < 10 || phone_number.length == 11 && phone_number[0] != 1
    puts "It is invalid number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    # legislators = legislators.officials
    # legislator_names = legislators.map(&:name)
    # legislator_names.join(", ")
  rescue
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

def count_hours_frequency(times)
  times.max_by { |a| times.count(a) }
  # times.reduce(Hash.new(0)) do |hsh, day|
  #   hsh[day] += 1
  #   hsh
  # end
  #  times.tally
end

def count_days_frequeny(days)
  days.max_by { |a| days.count(a) }
  # day.wday
end

contents = CSV.open('event_attendees.csv',
                    headers: true,
                    header_converters: :symbol)

# ERB Template
template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

days = []
times = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])

  time = DateTime.strptime(row[:regdate], "%m/%d/%Y %H:%M") # "05/12/2015"
  # Convert string to time with minutes => time = time.strftime("%H:%M")
  time = time.hour
  times << time

  day = DateTime.strptime(row[:regdate], "%m/%d")
  day = day.strftime("%A")

  days << day

  zipcode = clean_zipcode(row[:zipcode])
  puts "Zipcode: #{zipcode}"
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

puts "Most people registered at #{count_hours_frequency(times)} o'clock"
puts "Most people registered at #{count_days_frequeny(days)}"