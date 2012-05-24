#!/usr/bin/ruby
require 'pp'
require 'open-uri'
require 'thread'

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


path = '/home/wallpapers/4chan/'
base_url = 'http://boards.4chan.org/'
#sections = %w(c
              #e
              #u
              #w)
sections = %w(w
              a
              c
              e
              u)
img_regex = /<span class="fileText".*?>File(?: ?: |)<a href="([^"]+)" target="_blank">([^<]+)<\/a>-\([\d.]+ .., (\d+)x(\d+)/

sections.each do |section|
  Dir.mkdir(path+section) unless File.exists?(path+section)
end

while 1
  threads = []
  cache = load_cache('%s/.4chan.yaml' % ENV['HOME'])
  sections.each do |section|
    16.times do |i|
      begin
        page_url = base_url+section+"/"+i.to_s
        puts "downloading %s" % page_url

        content = open(page_url).read
        # parsing page content
        content.gsub(img_regex) do |line|
          img = {}
          match = line.match(img_regex)
          img[:url] = match[1].sub(/^\/\//, 'http://')
          img[:name] = match[2]
          img[:size] = "%sx%s" % [match[3], match[4]]
          img[:dir] = "%s%s" % [path, section, img[:size]]
          img[:path] = "%s/%s_%s" % [img[:dir], img[:size], img[:name]]
          img[:h] = nil
          next if cache.include?(img[:name])
          # do not download small images
          if match[3].to_i < 1600
            cache << img[:name]
            #downloaded = downloaded + 1
            next
          end
          begin
            Dir.mkdir(img[:dir]) unless File.exists?(img[:dir])
            puts "downloading %s [%s]" % [img[:url], img[:size]]
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
