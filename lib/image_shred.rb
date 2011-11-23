require 'chunky_png'
require_relative 'image_slice'

class ImageShred
  def initialize(filename)
    
  end
    
end

p "Program #{$PROGRAM_NAME} called."
p "Args..."
ARGV.each do|a|
  puts "Argument: #{a}"
end
p "...done"

exit # DEBUG