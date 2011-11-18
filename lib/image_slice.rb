require 'chunky_png'

class ImageSlice
  attr_reader :left_col
  attr_reader :slice_number
  attr_reader :neighbor_info
  attr_reader :likely_next_slice_info
  attr_reader :average_neighbor_diff
  attr_reader :start_col_idx, :end_col_idx
  
  def initialize(slice_number, source_img, start_col_idx, end_col_idx)
    @slice_number, @source_img, @start_col_idx, @end_col_idx = slice_number, source_img, start_col_idx, end_col_idx
    @left_col = source_img.column start_col_idx
    @right_col = source_img.column end_col_idx
    @neighbor_info = []
  end
  
  def self.pixel_diff(a, b)
    (ChunkyPNG::Color.grayscale_teint(a) - ChunkyPNG::Color.grayscale_teint(b)).abs
  end
  
  def self.calculate_column_diff(left_col, right_col)
    diff = 0
    left_col.each_with_index do |val, idx|
      diff += pixel_diff(val, right_col[idx])
    end
    diff
  end
  
  NeighborInfo = Struct.new(:slice_number, :diff)
  
  def analyze_right_left_matches(other_slices, verbose = nil)
    # find all the diffs compared to each of the others
    puts "--------------------- analyze_right_left_matches for slice #{slice_number}" if verbose
    other_slices.each do |other|
      total_diff = self.class.calculate_column_diff @right_col, other.left_col
      @neighbor_info << NeighborInfo.new(other.slice_number, total_diff)
      puts sprintf "  %2d %15d", other.slice_number, total_diff if verbose
    end
    # now find the likely next slice
    @average_neighbor_diff = 0
    @likely_next_slice_info = @neighbor_info[0]
    @neighbor_info[1..-1].each do |info|
      @average_neighbor_diff += info.diff
      @likely_next_slice_info = info if info.diff < @likely_next_slice_info.diff
    end
    @average_neighbor_diff /= @neighbor_info.size
  end
end