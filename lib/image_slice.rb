class ImageSlice
  attr_reader :left_col
  attr_reader :slice_number
  attr_reader :neighbor_info
  
  def initialize(slice_number, source_img, start_col_idx, end_col_idx)
    @slice_number, @source_img, @start_col_idx, @end_col_idx = slice_number, source_img, start_col_idx, end_col_idx
    @left_col = source_img.column start_col_idx
    @right_col = source_img.column end_col_idx
    @neighbor_info = []
    @likely_next_idx = nil
  end
  
  def self.calulate_column_diff(left_col, right_col)
    diff = 0
    left_col.each_with_index do |val, idx|
      diff += (val - right_col[idx]).abs
    end
    diff
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
  
  def likely_next_idx
    @likely_next_idx ||= lambda {
      likely_neighbor = @neighbor_info[0]
      @neighbor_info[1..-1].each do |info|
        likely_neighbor = info if likely_neighbor.diff > info.diff
      end
      @likely_next_idx = likely_neighbor.slice_number
    }.call
  end
end