class ImageSlice
  attr_reader :left_col
  attr_reader :slice_number
  attr_reader :neighbor_info
  
  def initialize(slice_number, source_img, start_col_idx, end_col_idx)
    @slice_number, @source_img, @start_col_idx, @end_col_idx = slice_number, source_img, start_col_idx, end_col_idx
    @left_col = source_img.column start_col_idx
    @right_col = source_img.column end_col_idx
    @neighbor_info = []
  end
  
  NeighborInfo = Struct.new(:slice_number, :diff)
  
  def analyze_right_left_matches(other_slices)
    other_slices.each do |other|
      total_diff = 0
      @right_col.each_with_index do |val, idx|
        total_diff += (val - other.left_col[idx]).abs
      end
#      puts total_diff
      @neighbor_info << NeighborInfo.new(other.slice_number, total_diff)
    end
  end
end