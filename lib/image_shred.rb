require 'chunky_png'
require_relative 'image_slice'

class ImageShred
  def initialize(filename)
    
  end
    
end

#p "Program #{$PROGRAM_NAME} called."
#p "Args..."
#ARGV.each do|a|
#  puts "Argument: #{a}"
#end
#p "...done"

filename = ARGV[0]
unless filename
  p "--- Image Shredder --- you must specify a filename to shred"
  p "  try: 'rake shred[filename]'"
  p "   or: 'bundle exec ruby lib/image_shred.rb filename'"
  exit
end

is = ImageShred.new filename

exit # DEBUG