#!/usr/bin/env ruby
require 'net/http'
require 'uri'

class Lipsum
    attr :type
    attr :count
    def initialize(count, type)
        case type
        when 'p'
            @type='paras'
        when 'w'
            @type='words'
        when 'b'
            @type='bytes'
        when 'l'
            @type='lists'
        else
            @type='words'
        end
        if count == nil
            @count = 5
        else
            @count = count
        end
    end

    def get
        url = URI.parse('http://lipsum.com/feed/html')
        params = { :amount => @count, :what => @type }
        url.query = URI.encode_www_form(params)
        res = Net::HTTP.get_response(url)
        doc = Hpricot(res.body)
        doc.search('#lipsum').each do |e|
            # Put in the clipboard
            IO.popen('xclip', 'w').print e.inner_text
        end
    end
end

begin
    require 'hpricot'
rescue LoadError
    puts "You need to install hpricot gem "
    exit!(1)
end

if ARGV[0] == 'help'
    puts <<-eos
    lipsum [count] [p|w|b|l]
    eos
else
    if ARGV.length > 0
        count = ARGV[0]
        type = ARGV[1]
        if count.include? ' '
            type = count.split(' ')[1]
            count = count.split(' ')[0]
        end
    end
    Lipsum.new(count, type).get
    puts "Text in Clipboard!"
end
