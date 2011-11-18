require 'chunky_png'
require_relative 'image_slice'

image_locn = "data"
image_name = "#{image_locn}/shredded_image.png"
slice_size = 32

puts "reading in img..."
img = ChunkyPNG::Image.from_file(image_name)
puts "...done"

dim = img.dimension
puts "Image dimensions (H:W): #{dim.height}:#{dim.width}"
max_idx = dim.width - 1

#puts "Finding slice points"
#diff_array = []
#left_col = img.column 0
#(1..max_idx).each do |idx|
#  right_col = img.column idx
#  diff_array << ImageSlice.calculate_column_diff(left_col, right_col)
#  left_col = right_col
#end
##  puts "#{idx-1}-#{idx}: #{ImageSlice.calulate_column_diff left_col, right_col}"
#diff_array[0..-2].each_with_index do |val, idx|
#  next_val = diff_array[idx+1]
#  puts "- break point at col #{idx+1}-#{idx+2}" if next_val > val*2
#end

puts "Creating slices based on known fixed width of: #{slice_size}"
slices = []
slice_number = left_idx = 0
loop do
  right_idx = left_idx + slice_size - 1
  right_idx = max_idx if right_idx > max_idx
  slices << ImageSlice.new(slice_number, img, left_idx, right_idx)
  puts "- Slice #{slice_number} using col #{left_idx}-#{right_idx}"
  break if right_idx == max_idx
  left_idx = right_idx+1
  slice_number += 1
end
puts "There are #{slices.size} slices"

slices.each_with_index do |slice, idx|
  slice.analyze_right_left_matches slices - [slice]
  likely_next = slice.likely_next_slice_info
  puts sprintf "Slice %2d has likely next idx of %2d - %15d (%3d%%)", 
    idx, likely_next.slice_number, likely_next.diff, 
    (100 * likely_next.diff.to_f / slice.average_neighbor_diff).to_i  
end

## now write them out in pairs
#slices.each do |slice|
#  name = "#{image_locn}/#{slice.slice_number}_#{slice.likely_next_slice_info.slice_number}_potential.png"
#  sample = ChunkyPNG::Image.new slice_size*2, dim.height
#  tgt_idx = 0
#  (slice.start_col_idx..slice.end_col_idx).each do |idx|
#    sample.replace_column! tgt_idx, img.column(idx)
#    tgt_idx += 1
#  end
#  slice = slices[slice.likely_next_slice_info.slice_number]
#  (slice.start_col_idx..slice.end_col_idx).each do |idx|
#    sample.replace_column! tgt_idx, img.column(idx)
#    tgt_idx += 1
#  end
#  puts "Writing sample file #{name}"
#  sample.save name
#end
