require 'chunky_png'
require_relative 'image_slice'

puts "reading in img..."
img = ChunkyPNG::Image.from_file('data/shredded_image.png')
puts "...done"

dim = img.dimension
puts "Image dimensions (H:W): #{dim.height}:#{dim.width}"

puts "Creating slices"
slices = []
slice_size = 32
max_idx = dim.width - 1
0.step(max_idx, slice_size) do |left_idx|
  slices << ImageSlice.new(0, img, left_idx, left_idx+slice_size-1)
end
puts "There are #{slices.size} slices"

slices[0].analyze_right_left_matches slices[1..-1]
