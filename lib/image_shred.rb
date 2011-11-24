require 'chunky_png'
require_relative 'image_slice'

class ImageShred
  def initialize(filename)
    @fname_orig = filename
    @img = ChunkyPNG::Image.from_file(filename)
  end
end

puts "--- Image Shredder ---"
filename = ARGV[0]
unless filename
  puts "- you must specify a filename to shred"
  puts "  try: 'rake shred[filename]'"
  puts "   or: 'bundle exec ruby lib/image_shred.rb filename'"
  exit
end

begin
  is = ImageShred.new filename
  is.process
  is.output
rescue StandardError => err
  puts "- processing error: #{err.message}"
end

exit # DEBUG