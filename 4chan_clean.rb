#!/usr/bin/ruby
require 'rubygems'
require 'ap'

wallpapers_path = '/home/wallpapers'
forchan_path = '/home/wallpapers/4chan'

EXCLUDES = ['.', '..', '4chan.rb', '4chan_clean.rb', '4chan']
def load_files(path, data)
  Dir.entries(path).each do |entry|
    next if EXCLUDES.include?(entry)
    if FileTest.directory?(path+'/'+entry)
      load_files(path+'/'+entry, data) 
      next
    end
    #next if entry !~ @@extensions

    data << (path+'/'+entry).gsub(' ', '\ ').gsub('(', '\(').gsub(')', '\)')
  end
end

duplicates = {}
wallpapers_data = []
load_files(wallpapers_path, wallpapers_data)
puts "%i wallpapers were found" % wallpapers_data.size
wallpapers_data.each do |filename|
  duplicates[File.size(filename.gsub('\\', ''))] = filename
end

data = []
load_files(forchan_path, data)
puts "%i 4chan files were found" % data.size

deleted_files = 0
empty_files = 0
duplicate_files = 0

data.each do |filename|
  sizes = filename.match(/(\d+)x(\d+)/)
  next unless sizes
  width = sizes[1].to_i
  height = sizes[2].to_i
  if width < 1000 || height > width || height*2 < width
    File.delete(filename)
    puts "%s deleted because of bad aspect ratio" % filename
    deleted_files += 1
    next
  end
  size = File.size(filename)
  if size == 0
    File.delete(filename)
    puts "%s was empty" % filename
    empty_files += 1
  end
  if duplicates.include?(size)
    File.delete(filename) if File.exists?(filename)
    puts "%s duplicate for %s" % [filename, duplicates[size]]
    duplicate_files += 1
  else
    duplicates[size] = filename
  end
end
puts "%i files were deleted" % deleted_files
puts "%i files were empty" % empty_files
puts "%i files were duplicates" % duplicate_files
puts "done"
