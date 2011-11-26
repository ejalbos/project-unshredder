require 'chunky_png'
require 'ostruct'
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
    # will also write out a single one with all the partials
    agg_pair_gap = 20
    total_width = @slices.inject(0) { |sum, slice| sum + slice.width*2 }
    total_width += (@slices.size-1) * agg_pair_gap
    aggregate = ChunkyPNG::Image.new total_width, @img.dimension.height
    agg_tgt_idx = 0
    @slices.each do |slice|
      next_slice = @slices[slice.likely_next_slice.slice_number]
      total_width = slice.width + next_slice.width
      sample = ChunkyPNG::Image.new total_width, @img.dimension.height
      
      tgt_idx = 0
      slice.transfer_self_at(sample, tgt_idx)
      slice.transfer_self_at(aggregate, agg_tgt_idx)
      tgt_idx += slice.width
      agg_tgt_idx += slice.width 

      next_slice.transfer_self_at(sample, tgt_idx)
      next_slice.transfer_self_at(aggregate, agg_tgt_idx)
      agg_tgt_idx += next_slice.width + agg_pair_gap
     
      name = @fname_orig.sub(/\.png\Z/, "_partial_#{slice.slice_number}_#{next_slice.slice_number}.png")
      puts "- writing pairing file #{name}"
      sample.save name
    end
    
    name = @fname_orig.sub(/\.png\Z/, "_partial_aggregate.png")
      puts "- writing pairing aggregate file #{name}"
    aggregate.save name
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
      break if (next_slice_number == @leftmost_slice_idx || tgt_idx >= @img.dimension.width)
      slice = @slices[next_slice_number]
    end
    reconstructed.save name
  end
  
  def determine_likely_ordering
    puts "- determining likely ordering"
    @slices.each do |slice|
      slice.preprocess
    end
    find_slice_pairs_based_on_lowest_diff
    possible_adjust_for_double_next_usage
  end
  
  def possible_adjust_for_double_next_usage
    # an unused slice means something used more than once on the right
    if unused_slice_idx = an_unused_right_slice
      puts "-- unused right slice with idx #{unused_slice_idx}"
      # find which slices are using which others
      next_usage = {}
      @slices.each do |slice|
        next_idx = slice.likely_next_slice.slice_number
        users = next_usage[next_idx] || []
        users << slice.slice_number
        next_usage[next_idx] = users
      end
      # now find the multiples
      overused_slice_idx = overusing_slices = nil
      next_usage.each do |k, v|
        if v.size > 1
          puts "-- slice #{k} multiply used by slices #{v}"
          overused_slice_idx = k
          overusing_slices = v
          break
        end
      end
      # now make the higher change ratio one use the unused slice
      max_change_ratio, idx_at_max = 0, nil
      overusing_slices.each do |idx|
        slice = @slices[idx]
        change_ratio = slice.likely_next_slice.diff_info.change_ratio
        if change_ratio > max_change_ratio
          max_change_ratio = change_ratio
          idx_at_max = idx
        end
      end
      @slices[idx_at_max].replace_likely_next_slice @slices[unused_slice_idx]
    else
      puts "- no unused right slices"
    end
  end
  
  def find_slice_pairs_based_on_lowest_diff
    @slices.each_with_index do |slice, idx|
      slice.analyze_right_left_matches @slices - [slice] ###, true
    end
  end
  
  def determine_cylinder_break
    break_method = "unused right slice"
    unless an_unused_right_slice
      find_by_max_change_ratio
      break_method = "max change ratio"
    end
    puts "- the starting slice is at idx = #{@leftmost_slice_idx}, found via #{break_method}"  
  end
  
  def an_unused_right_slice
    possible_slices = (0..@num_slices-1).to_a
    slices_used = @slices.map { |slice| slice.likely_next_slice.slice_number }
    slices_unused = possible_slices - slices_used
#    p slices_unused
    if slices_unused.size > 1
      raise "Excess unused slices: #{slices_unused}"
    elsif slices_unused.size == 1
      @leftmost_slice_idx = slices_unused[0]
    else
      false
    end
  end
  
  def find_by_max_change_ratio
    max_change_ratio = 0
    @leftmost_slice_idx = -1
    @slices.each do |slice|
      next_slice_change_ratio = slice.likely_next_slice.diff_info.change_ratio
      if next_slice_change_ratio > max_change_ratio
        max_change_ratio = next_slice_change_ratio
        @leftmost_slice_idx = slice.likely_next_slice.slice_number
      end
    end
  end
  
  def create_slices
    dim = @img.dimension
    puts "- image is #{dim.width}x#{dim.height} pixels"
    if @slice_width
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
    else
#      puts "- searching image for slices"
#      min_slice_width = ImageSlice::MINIMUM_SLICE_WIDTH
#      left_col, right_col = 0
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
