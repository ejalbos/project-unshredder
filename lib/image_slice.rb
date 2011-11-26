require 'chunky_png'
require 'ostruct'

class ImageSlice
  attr_reader :left_col
  attr_reader :slice_number
  attr_reader :neighbors
  attr_reader :likely_next_slice
  attr_reader :start_col_idx, :end_col_idx
  attr_reader :right_edge_left_diff
  
  def initialize(slice_number, source_img, start_col_idx, end_col_idx)
    @slice_number, @source_img, @start_col_idx, @end_col_idx = slice_number, source_img, start_col_idx, end_col_idx
    @left_col = source_img.column start_col_idx
    @right_col = source_img.column end_col_idx
  end
  
  def preprocess
    info = self.class.calculate_column_diff_info @source_img.column(end_col_idx-1), @right_col
    @right_edge_left_diff = info.total_diff
  end
  
  def width
    @end_col_idx - @start_col_idx + 1
  end
  
  def transfer_self_at(target_img, target_starting_idx)
    (@start_col_idx..@end_col_idx).each do |idx|
      target_img.replace_column! target_starting_idx, @source_img.column(idx)
      target_starting_idx += 1
    end
  end
  
  def self.pixel_diff(a, b)
    (ChunkyPNG::Color.grayscale_teint(a) - ChunkyPNG::Color.grayscale_teint(b)).abs
  end
  
  DiffInfo = Struct.new(:total_diff, :diff_range)
  
  def self.calculate_column_diff_info(left_col, right_col)
    total_diff = 0
    left_col.each_with_index do |val, idx|
      diff = pixel_diff(val, right_col[idx])
      total_diff += diff
    end
    OpenStruct.new(total_diff: total_diff)
  end
  
  NeighborInfo = Struct.new(:slice_number, :diff_info)
  
  def analyze_right_left_matches(other_slices, verbose = nil)
    # find all the diffs compared to each of the others
    puts "--------------------- analyze_right_left_matches for slice #{slice_number}" if verbose
    @neighbors = []
    other_slices.each do |other|
      diff_info = self.class.calculate_column_diff_info @right_col, other.left_col
      @neighbors << NeighborInfo.new(other.slice_number, diff_info)
      puts sprintf "  %2d %s", other.slice_number, diff_info.to_s if verbose
    end
    # now find the likely next slice
    @likely_next_slice = @neighbors[0]
    @neighbors[1..-1].each do |neighbor|
      diff_to_new_neighbor = neighbor.diff_info.total_diff
      @likely_next_slice = neighbor if diff_to_new_neighbor < @likely_next_slice.diff_info.total_diff
    end
  end
end