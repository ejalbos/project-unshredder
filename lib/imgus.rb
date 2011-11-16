require 'chunky_png'

puts "reading in img..."
img = ChunkyPNG::Image.from_file('data/shredded_image.png')
puts "...done"

dim = img.dimension

puts "Image dimensions (H:W): #{dim.height}:#{dim.width}"

puts "Hello World!"