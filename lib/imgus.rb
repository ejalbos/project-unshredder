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
#0.step(max_idx, slice_size) do |left_idx|
#  slices << ImageSlice.new(0, img, left_idx, left_idx+slice_size-1)
#end

slice_number = left_idx = 0
loop do
  right_idx = left_idx + slice_size - 1
  right_idx = max_idx if right_idx > max_idx
  slices << ImageSlice.new(slice_number, img, left_idx, right_idx)
  break if right_idx == max_idx
  left_idx = right_idx+1
  slice_number += 1
end

puts "There are #{slices.size} slices"

slices[0].analyze_right_left_matches slices[1..-1]
slices[0].neighbor_info.each do |info|
  puts "#{info.slice_number} - #{info.diff}"
end
