#!/usr/bin/env ruby
# Author Bend66
# blog.b42.eu

require 'rubygems'
require 'pathname'

CONF = "#{ENV['HOME']}/.cloudapp-conf"
APPNAME = "cloudapp"
begin
    require 'cloudapp_api'
rescue LoadError
    puts "You need to install cloudapp_api: run cloud install"
    exit!(1)
end

def authenticate
    unless File.exist?(CONF)
        puts "You need to run #{APPNAME} setup username password"
        exit!(1)
    end
    email, password = File.read(CONF).split("\n")
    CloudApp.authenticate(email,password)
end

def upload(path)
    unless File.exist?(CONF)
        puts "You need to run #{APPNAME} setup username password"
        exit!(1)
    end
    
    authenticate()

    unless File.exist?(path)
        puts "The specified file does not exist"
        exit 1
    end
    begin
        drop = CloudApp::Drop.create(:upload, :file => File.absolute_path(path))
    rescue
        puts "Access denied: Check your logins or quota"
        exit 1
    end


    # Get the embed link.
    path = Pathname.new(path).basename.to_s
    
    # Say it for good measure.
    puts "Uploaded to #{drop.url}"
    url = "#{drop.url}/#{path.split('/').last}"

    # Copy it to your (Mac's) clipboard.
    `echo '#{url}' | tr -d "\n" | pbcopy`
end

def install
    begin 
        require 'cloudapp_api'
        puts "Extension already installed"
    rescue LoadError
        system('gem install cloudapp_api > /dev/null')
        puts "Extension installed"
    end
end

def setup(username, password)
    File.open(CONF, 'w') do |f|
        f.puts username
        f.puts password
    end
    puts 'You can now upload a file to your cloudapp accound'
end

def list
    authenticate()
    i = 0
    CloudApp::Drop.all.each do |e|
        puts "#{i} URL : #{e.url} #{e.name}"
        i+=1
    end
end

def rename(id, new_name)
    authenticate
    i = 0
    obj = nil
    CloudApp::Drop.all.each do |e|
        if i.to_i == id.to_i
            obj = e
        end
        i+=1
    end
    if obj == nil
        puts "Unknown file index"
        exit 0
    end
    old_name = obj.name
    obj.update(:name => new_name)
    puts "Renamed file #{old_name} to #{new_name}"
end

def delete(id)
    authenticate
    i = 0
    obj = nil
    CloudApp::Drop.all.each do |e|
        if i.to_i == id.to_i
            obj = e
        end
        i+=1
    end
    if obj == nil
        puts "Unknown file index"
        exit 0
    end
    obj.delete
    puts "Deleted file #{obj.name}"
end

def delete_name(name)
    authenticate
    obj = nil
    CloudApp::Drop.all.each do |e|
        if e.name == name
            if obj != nil
                puts "Multiple files with same name found"
                puts "Please use the delete option with index"
                exit 0
            end
            obj = e
        end
    end
    if obj == nil
        puts "File name not found"
        exit 0
    end
    obj.delete
    puts "Deleted file #{obj.name}"
end


def help
    puts "Usage: #{APPNAME} options"
    puts "options :"
    puts "install : install the required libraries"
    puts "setup username password : save your username and password"
    puts "[path]: upload file to cloudapp"
    puts "list : list all files"
    puts "rename id new_name : rename file with id "
    puts "delete id : delete file with id"
    puts "deletebn name : delete file with matching name" 
end

if ARGV.size == 0 
    help
else
    case ARGV[0]
    when 'help'
        help
    when 'install'
        install
    when 'setup'
        if ARGV.size == 3
            setup(ARGV[1], ARGV[2])
        else
            help
        end
    when 'list'
        list
    when 'rename'
        if ARGV.size == 3
            rename(ARGV[1], ARGV[2])
        else 
            help
        end
    when 'delete'
        if ARGV.size == 2
            delete(ARGV[1])
        end
    when 'deletebn'
        if ARGV.size == 2
            delete_name(name)
        end
    else
        upload(ARGV[0])
    end
end
