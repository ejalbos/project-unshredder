require 'chunky_png'

class ImageSlice
  attr_reader :left_col
  attr_reader :slice_number
  attr_reader :neighbor_info
  attr_reader :likely_next_slice_info
  attr_reader :average_neighbor_diff
  attr_reader :start_col_idx, :end_col_idx
  attr_reader :right_edge_left_diff
  
  def initialize(slice_number, source_img, start_col_idx, end_col_idx)
    @slice_number, @source_img, @start_col_idx, @end_col_idx = slice_number, source_img, start_col_idx, end_col_idx
    @left_col = source_img.column start_col_idx
    @right_col = source_img.column end_col_idx
    @neighbor_info = []
    info = self.class.calculate_column_diff_info source_img.column(end_col_idx-1), @right_col
    @right_edge_left_diff = info.total_diff
  end
  
  def self.pixel_diff(a, b)
    (ChunkyPNG::Color.grayscale_teint(a) - ChunkyPNG::Color.grayscale_teint(b)).abs
  end
  
  DiffInfo = Struct.new(:total_diff, :diff_range)
  
  def self.calculate_column_diff_info(left_col, right_col)
    diff_min = 1000
    diff_max = 0
    total_diff = 0
    left_col.each_with_index do |val, idx|
      diff = pixel_diff(val, right_col[idx])
      total_diff += diff
      diff_min = diff if diff < diff_min
      diff_max = diff if diff > diff_max
    end
    DiffInfo.new total_diff, diff_max - diff_min
  end
  
  NeighborInfo = Struct.new(:slice_number, :diff_info)
  
  def analyze_right_left_matches(other_slices, verbose = nil)
    # find all the diffs compared to each of the others
    puts "--------------------- analyze_right_left_matches for slice #{slice_number}" if verbose
    other_slices.each do |other|
      diff_info = self.class.calculate_column_diff_info @right_col, other.left_col
      @neighbor_info << NeighborInfo.new(other.slice_number, diff_info)
      puts sprintf "  %2d %10d, %5d", other.slice_number, diff_info.total_diff, diff_info.diff_range if verbose
    end
    # now find the likely next slice
    @average_neighbor_diff = 0
    @likely_next_slice_info = @neighbor_info[0]
    @neighbor_info[1..-1].each do |neighbor_info|
      diff = neighbor_info.diff_info.total_diff
      @average_neighbor_diff += diff
      @likely_next_slice_info = neighbor_info if diff < @likely_next_slice_info.diff_info.total_diff
    end
    @average_neighbor_diff /= @neighbor_info.size
  end
end