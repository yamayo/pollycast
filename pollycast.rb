require 'aws-sdk'
require 'curb'
require 'feedjira'

def curl
  @curl ||= Curl::Easy.new.tap {|instance|
    instance.follow_location = true
    instance.max_redirects = 6
    instance.useragent = 'curb'
  }
end

def response_for(url)
  curl.url = url
  curl.timeout = 60
  curl.perform && curl.status == '200 OK' ? curl.body_str : nil
rescue Curl::Err::TimeoutError => e
  raise e
end

def parse_feed(url)
  res = response_for(url)
  Feedjira::Feed.parse(res)
end

url = 'http://feeds.feedburner.com/TechCrunch/'
feed = parse_feed(url)

polly = Aws::Polly::Client.new(region: 'us-east-1')

feed.entries.each.with_index do |entry, index|
  break if index == 3 # Guard
  file_name = "#{entry.published}.mp3"
  next if File.exists?(file_name)

  content = Nokogiri::HTML(entry.summary).text
  polly.synthesize_speech(
    response_target: file_name,
    output_format: 'mp3',
    text: entry.title + content,
    voice_id: 'Geraint',
  )
end
