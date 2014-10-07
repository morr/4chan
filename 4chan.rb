##!/usr/bin/ruby
require 'pp'
require 'open-uri'
require 'thread'
require 'nokogiri'
require 'pry'

def load_cache(path)
  cache = nil
  begin
    File.open(path, "r") {|f| cache = Marshal.load(f) } if File.exists?(path)
  rescue
  ensure
    cache = [] unless cache
  end
  cache
end

def save_cache(path, cache)
  File.open(path, "w") {|f| Marshal.dump(cache, f) }
end


path = '/tmp/4chan/'
base_url = 'http://boards.4chan.org/'
#sections = %w(c e u w)
#sections = %w(w a c e u)
sections = %w(w)

Dir.mkdir path unless File.exists? path
sections.each do |section|
  Dir.mkdir path+section unless File.exists? path+section
end

while true
  cache = load_cache('%s/.4chan.yaml' % ENV['HOME'])
  sections.each do |section|
    10.times do |i|
      begin
        page_url = "#{base_url}#{section}/#{i}"
        puts "downloading #{page_url}"

        content = open(page_url).read
        doc = Nokogiri::HTML(content)
        files = doc.css('.file')

        files.each do |file_node|
          img = {}

          img[:url] = file_node.css('.fileThumb').first.attr('href').sub(/^\/\//, 'http://')
          img[:name] = file_node.css('.fileText a').first.text
          img[:sizes] = file_node.css('.fileText').text =~ / (?<sizes>\d+x\d+)\)/ && $~[:sizes]
          img[:dir] = "#{path}#{section}"
          img[:path] = "#{img[:dir]}/#{img[:sizes]}_#{img[:name]}"

          next if cache.include? img[:name]

          # do not download small images
          if img[:sizes].split('x').first.to_i < 1600
            cache << img[:name]
            #downloaded = downloaded + 1
            next
          end
          begin
            Dir.mkdir(img[:dir]) unless File.exists?(img[:dir])
            puts "downloading %s [%s]" % [img[:url], img[:sizes]]
            open(img[:url]) do |h|
              File.open(img[:path], "w") {|file| file.write(h.read) }
            end
            cache << img[:name]
          rescue Exception => e
            raise Interrupt.new if e.class == Interrupt
            puts e.message
            puts e.backtrace.join("\n")
          end # rescue
          #downloaded = downloaded + 1
        end # gsub
        #break if downloaded == 0

      rescue Exception => e
        exit if e.class == Interrupt
        puts e.message
        puts e.backtrace.join("\n")
      end # rescue
    end # times
  end # each
  save_cache('%s/.4chan.yaml' % ENV['HOME'], cache)
  puts "%s done" % Time.new.strftime("%Y-%m-%d %H:%M:%S")
  sleep(60*60*0.5)
end # while
