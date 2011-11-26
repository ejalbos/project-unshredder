require 'chunky_png'
require_relative 'image_slice'

class ImageUnshred
  def initialize(filename, slice_width)
    @fname_orig = filename
    @slice_width = slice_width
    puts "Reading in '#{filename}'..."
    @img = ChunkyPNG::Image.from_file(filename)
    puts "... input done."
  end
  
  def process
    puts "Processing image..."
    create_slices
    determine_likely_ordering
    determine_cylinder_break
    puts "... processing done."
  end
  
  def output
    @unshredded_fname = @fname_orig.sub(/\.png\Z/, "_unshredded.png")
    puts "Outputting pairings and final unshredded image..."
    output_partials
    output_unshredded_image
    puts "... output done."
  end
  
private
  
  def output_partials
    # now write them out in pairs
    @slices.each do |slice|
      next_slice = @slices[slice.likely_next_slice.slice_number]
      total_width = slice.width + next_slice.width
      sample = ChunkyPNG::Image.new total_width, @img.dimension.height
      
      tgt_idx = 0
      slice.transfer_self_at(sample, tgt_idx)
      tgt_idx += slice.width
      next_slice.transfer_self_at(sample, tgt_idx)
      
      name = @fname_orig.sub(/\.png\Z/, "_potential_#{slice.slice_number}_#{next_slice.slice_number}.png")
      puts "- writing pairing file #{name}"
      sample.save name
    end
  end
 
  def output_unshredded_image
    # Finally, once I've found the start, write out the whole image
    name = @fname_orig.sub(/\.png\Z/, "_unshredded.png")
    puts "- writing unshredded file #{name}"
    reconstructed = ChunkyPNG::Image.new @img.dimension.width, @img.dimension.height
    slice = @slices[@leftmost_slice_idx]
    tgt_idx = 0
    loop do
      slice.transfer_self_at(reconstructed, tgt_idx)
      tgt_idx += slice.width
      next_slice_number = slice.likely_next_slice.slice_number
      break if next_slice_number == @leftmost_slice_idx
      slice = @slices[next_slice_number]
    end
    reconstructed.save name
  end
  
  BreakInfo = Struct.new(:slice, :right_edge_left_diff, :slice_diff)
  
  def determine_likely_ordering
    puts "- determining likely ordering"
    @slices.each do |slice|
      slice.preprocess
    end
    @break_info = []
    @slices.each_with_index do |slice, idx|
      slice.analyze_right_left_matches @slices - [slice] ###, true
      likely_next = slice.likely_next_slice
      info =  BreakInfo.new(slice, slice.right_edge_left_diff, likely_next.diff_info.total_diff) 
      puts sprintf "-- slice %2d has likely next idx of %2d   -  right_edge_left_diff = %5d, slice_diff = %5d", 
        idx, likely_next.slice_number, info.right_edge_left_diff, info.slice_diff 
      @break_info << info
    end
  end
  
  def determine_cylinder_break
    start_slice_idxs = []
    puts "- determining image break point"
    @break_info.each do |info|
      start_slice_idxs << info.slice.likely_next_slice.slice_number if info.slice_diff > 3*info.right_edge_left_diff
    end
    if start_slice_idxs.size == 0
      raise "Unable to determine a starting slice"
    elsif start_slice_idxs.size > 1
      raise "Found the following multiple starting slices: #{start_slice_idxs}"
    end

    @leftmost_slice_idx = start_slice_idxs[0]
    puts "- the starting slice is at idx = #{@leftmost_slice_idx}"  
  end
  
  def create_slices
    dim = @img.dimension
    puts "- image is #{dim.width}x#{dim.height} pixels"
    @num_slices = dim.width / @slice_width
    puts "- creating slices based on known slice width of #{@slice_width} pixels"
    @slices = []
    left_col, right_col = 0, @slice_width-1
    @num_slices.times do |idx|
      @slices << ImageSlice.new(idx, @img, left_col, right_col)
      puts "-- slice #{idx} using col #{left_col}-#{right_col}"
      left_col += @slice_width
      right_col += @slice_width
    end
    puts "- there are #{@slices.size} slices"
  end
end

#===================================================== MAIN

puts "--- Image UnShredder: BEGIN ---"
filename = ARGV[0]
slice_width = ARGV[1]
unless filename && slice_width
  puts "- you must specify a filename to unshred"
  puts "  try: 'rake unshred[filename, slice_width]'"
  puts "   or: 'bundle exec ruby lib/image_unshred.rb filename slice_width'"
  puts "NOTE: slice_width is currently mandatory"
  exit
end

  ius = ImageUnshred.new filename, slice_width.to_i
  ius.process
  ius.output
begin
rescue StandardError => err
  puts "- processing error: #{err.message}"
end

puts "--- Image UnShredder: END ---"
