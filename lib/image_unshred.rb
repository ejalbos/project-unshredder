require 'chunky_png'
require_relative 'image_slice'

image_locn = "data"
image_name = "#{image_locn}/shredded_image.png"
slice_size = 32

puts "Reading in img..."
img = ChunkyPNG::Image.from_file(image_name)
puts "...done."

dim = img.dimension
puts "Image dimensions (H:W): #{dim.height}:#{dim.width}"
max_idx = dim.width - 1

#puts "Finding slice points"
## get the first differential
#diff_info_array = []
#left_col = img.column 0
#(1..max_idx).each do |idx|
#  right_col = img.column idx
#  diff_info_array << ImageSlice.calculate_column_diff_info(left_col, right_col)
#  left_col = right_col
#end
## and now the second differential
##  puts "#{idx-1}-#{idx}: #{ImageSlice.calulate_column_diff left_col, right_col}"
##diff_info_array[0..-2].each_with_index do |val, idx|
#diff_diff = []
#prev_diff = 0
#diff_info_array[0..-2].each_with_index do |val, idx|
#  this_diff = val.total_diff
#  diff_diff << this_diff - prev_diff
#  puts sprintf "Slice %3d-%3d, diffs = %5d, %7d", idx, idx+1, this_diff, diff_diff.last
#  prev_diff = this_diff
##  next_val = diff_array[idx+1]
##  puts "- break point at col #{idx+1}-#{idx+2}" if next_val > val*2
#end
#
#exit # DEBUG

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

BreakInfo = Struct.new(:slice, :right_edge_left_diff, :slice_diff)

break_info = []
slices.each_with_index do |slice, idx|
  slice.analyze_right_left_matches slices - [slice] ###, true
  likely_next = slice.likely_next_slice_info
  info =  BreakInfo.new(slice, slice.right_edge_left_diff, likely_next.diff_info.total_diff) 
  puts sprintf "Slice %2d has likely next idx of %2d   -  right_edge_left_diff = %5d, slice_diff = %5d", 
    idx, likely_next.slice_number, info.right_edge_left_diff, info.slice_diff 
  break_info << info
end

start_slice_idxs = []
puts "Determining image break point..."
break_info.each do |info|
  start_slice_idxs << info.slice.likely_next_slice_info.slice_number if info.slice_diff > 3*info.right_edge_left_diff
end
if start_slice_idxs.size == 0
  puts "Unable to determine a starting slice"
  exit
elsif start_slice_idxs.size > 1
  puts "Found the folloing multiple starting slices: #{start_slice_idxs}"
  exit
end

leftmost_slice_idx = start_slice_idxs[0]
puts "The starting slice is idx = #{leftmost_slice_idx}"

# now write them out in pairs
slices.each do |slice|
  name = "#{image_locn}/#{slice.slice_number}_#{slice.likely_next_slice_info.slice_number}_potential.png"
  sample = ChunkyPNG::Image.new slice_size*2, dim.height
  tgt_idx = 0
  (slice.start_col_idx..slice.end_col_idx).each do |idx|
    sample.replace_column! tgt_idx, img.column(idx)
    tgt_idx += 1
  end
  slice = slices[slice.likely_next_slice_info.slice_number]
  (slice.start_col_idx..slice.end_col_idx).each do |idx|
    sample.replace_column! tgt_idx, img.column(idx)
    tgt_idx += 1
  end
  puts "Writing sample file #{name}"
  sample.save name
end

#leftmost_slice_idx = 8
# Finally, once I've found the start, write out the whole image
name = image_name.gsub(/\.png/, "_unshredded.png")
puts "Writing reconstructed file #{name}..."
reconstructed = ChunkyPNG::Image.new dim.width, dim.height
slice = slices[leftmost_slice_idx]
tgt_idx = 0
loop do
  (slice.start_col_idx..slice.end_col_idx).each do |idx|
    reconstructed.replace_column! tgt_idx, img.column(idx)
    tgt_idx += 1
  end
  next_slice_numer = slice.likely_next_slice_info.slice_number
  break if next_slice_numer == leftmost_slice_idx
  slice = slices[next_slice_numer]
end
reconstructed.save name
puts "...done."

