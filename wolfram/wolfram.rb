#!/usr/bin/ruby

require 'net/http'
require 'uri'

API_KEY = "XXXX-XXXXXXXXXX"  # Set your api key here
class Wolfram
   attr :request
  def initialize(request)
     @request = request
   end

  def get
     url = URI.parse('http://api.wolframalpha.com/v2/query')
     params = { :input => @request, :appid => API_KEY, :reinterpret => 'true'}
     url.query = URI.encode_www_form(params)
     res = Net::HTTP.get_response(url)
     doc = Hpricot(res.body)
     result = doc.search('plaintext')
     result.each do |e|
         e.inner_text.each_line do |l|
            l.capitalize!
            l.strip
            puts "#{l}"
         end
     end
     if result.size == 0
        tips = doc.search('tip')
        if tips.size == 0
           puts "No Results found"
        else
           puts tips.attr('text')
        end
     end
  end
end

begin
    require 'hpricot'
rescue LoadError
    puts "You need to install Hpricot gem"
    exit!(1)
end

if ARGV.length == 0
   puts "Usage: wolfram query"
else
   str=""
   ARGV.each do |e|
      str+=e+' '
   end
   Wolfram.new(str).get
end
