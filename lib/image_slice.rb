class ImageSlice
  def initialize(source_img, start_col_idx, end_col_idx)
    @source_img, @start_col_idx, @end_col_idx = source_img, start_col_idx, end_col_idx
    @left_col = source_img.column start_col_idx
    @right_col = source_img.column end_col_idx
  end
end