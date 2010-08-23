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
sections = %w(a
              c
              e
              u
              w)
img_regex = /<span class="filesize">File(?: : |)<a href="([^"]+)" target="_blank">([^<]+)<\/a>-\([\d.]+ .., (\d+)x(\d+)\)<\/span>/#<br><a href="([^"]+)" target=_blank>/#<img src=http://1.thumbs.4chan.org/w/thumb/1279393057447s.jpg border=0 align=left width=251 height=189 hspace=20 alt="981 KB" md5="gmvBwSW+XGwc/7Hu7caRlQ==">/

sections.each do |section|
  Dir.mkdir(path+section) unless File.exists?(path+section)
end

while 1
  mutex = Mutex.new
  threads = []
  cache = load_cache('%s/.4chan.yaml' % ENV['HOME'])
  sections.each do |section|
    threads << Thread.new(section) do |section|
      16.times do |i|
        begin
          page_url = base_url+section+"/"+i.to_s
          puts "downloading %s" % page_url

          downloaded = 0
          content = nil
          open(page_url) {|h| content = h.read }
          # parsing page content
          content.gsub(img_regex) do |line|
            img = {}
            match = line.match(img_regex)
            img[:url] = match[1]
            img[:name] = match[2]
            img[:size] = "%sx%s" % [match[3], match[4]]
            img[:dir] = "%s%s" % [path, section, img[:size]]
            img[:path] = "%s/%s_%s" % [img[:dir], img[:size], img[:name]]
            img[:h] = nil

            next if cache.include?(img[:name])
            # do not download small images
            if match[3].to_i < 1280
              cache << img[:name]
              downloaded = downloaded + 1
              next
            end
            begin
              Dir.mkdir(img[:dir]) unless File.exists?(img[:dir])
              puts "downloading %s [%s]" % [img[:url], img[:size]]
              open(img[:url]) do |img[:h]|
                File.open(img[:path], "w") {|file| file.write(img[:h].read) }
              end
              mutex.lock
              cache << img[:name]
              save_cache('%s/.4chan.yaml' % ENV['HOME'], cache)
              mutex.unlock
            rescue Exception => e
              puts e.message
              raise Interrupt.new if e.class == Interrupt
            end # rescue
            downloaded = downloaded + 1
          end # gsub
          break if downloaded == 0

        rescue Exception => e
          exit if e.class == Interrupt
          puts e.message
        end # rescue
      end # times
    end # threads
  end # each
  threads.each { |aThread| aThread.join }
  puts "%s done" % Time.new.strftime("%Y-%m-%d %H:%M:%S")
  sleep(60*60*2)
end # while
