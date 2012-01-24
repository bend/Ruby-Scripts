#!/usr/bin/env ruby
BAR_LENGTH = 100

module Tty extend self
    def blue; bold 34; end
    def white; bold 39; end
    def redu; underline 31; end
    def red; bold 31; end
    def reset; escape 0; end
    def bold n; escape "1;#{n}" end
    def underline n; escape "4;#{n}" end
    def escape n; "\033[#{n}m" if STDOUT.tty? end
end

#
# Print a progress bar on STDOUT
# 
def print_percent(p)
    print "\r"
    print "#{Tty.red}[#{Tty.reset}"
    nb_char = BAR_LENGTH * (p/100.0)
    for i in 0 .. nb_char.to_i do
        print "#{Tty.blue}##{Tty.reset}"
    end
    for i in nb_char.to_i + 1 .. BAR_LENGTH do
        print "#{Tty.white}_#{Tty.reset}"
    end
    print "#{Tty.red}] - #{p}%#{Tty.reset}"
end

def set_chunk_size(size)
    if size > 10240000
        return size/BAR_LENGTH
    else return 102400
    end
end

def perr(msg)
    puts "#{Tty.redu}Error: #{msg} #{Tty.reset}"
end

def copy_file(from, to)
    begin
        # Check if source exist
        if !File.exists?(from)
            perr "Unexisting file"
            exit!
        end
        # Open the source file for reading
        file_in = File.new(from, "r")
        # Get the size for the progress bar
        size = file_in.size
        chunk_size = set_chunk_size(size)
        current_size = 0.0
        # Check if we are copying to a file or a dir 
        # and set the corresponding name
        if File.directory?(to)
            to = to+"/"+File.basename(from)
        end
        # Check if source == dest
        if File.absolute_path(from) == File.absolute_path(to)
            perr "Source and destination are the same"
            exit!
        end
        puts "Copying #{from} to #{to}"
        # Open dest file for writing
        file_out = File.new(to, "w")
        # Start copying
        while(current_size < size)
            chunk = file_in.read(chunk_size)
            file_out.write(chunk)
            current_size += chunk.size
            percentage = ((current_size/size)*100.0).to_i
            print_percent(percentage)
        end
        # We are done
        print_percent 100
        puts ""
        # Close all files
        file_in.close
        file_out.close
    rescue => err
        perr "#{err}"
    end
end

def copy_dir(from, to)
    # Check that we are not copying to a file
    if File.file?(to)
        perr "Destination is a file"
        exit
    end
    # If dest dir doesen't print error
    if !File.exist?(to)
        Dir.mkdir(to)
    end
    if !File.exist?(to+"/"+File.basename(from))
        Dir.mkdir(to+"/"+File.basename(from))
    end
    # Foreach entry, copy it
    Dir.entries(from).each do |f|
        if f != '.' and f !='..'
            copy(from+"/"+f,to+"/"+File.basename(from)+"/"+f)
        end
    end
end

def copy(from, to)
    if !File.exists? from
        perr "File not found : #{from}"
        exit! 0
    end
    if File.directory?(from)
        copy_dir(from, to)
    elsif File.file?(from)
        copy_file(from, to)
    elsif File.symlink?(from)
        copy_file(from, to)
    else
        perr "Cannot copy this type of file"
    end
end

def copy_all(arr)
    # Check that we are not copying to a file
    if File.file?(arr[-1])
        perr "Destination is a file"
        exit
    end
    # If dest dir doesen't exist create it
    if !File.exist?(arr[-1])
        Dir.mkdir(arr[-1])
    end
    # Copy each file or dir
    for i in 0..arr.size - 2
        copy(arr[i], arr[-1])
    end
end


def usage
    puts "Usage : ecp source destination"
end

def main
    trap("SIGINT") do
        puts ""
        exit!
    end
    if ARGV.size < 2
        usage
    else
        if ARGV.size == 2
            copy(ARGV[0], ARGV[1])
        else
            copy_all(ARGV)
        end
    end
end

main
