require 'chunky_png'
require_relative 'image_slice'

class ImageShred
  def initialize(filename)
    @fname_orig = filename
    puts "Reading in '#{filename}'..."
    @img = ChunkyPNG::Image.from_file(filename)
    puts "... input done."
  end
  
  def process
    puts "Processing image..."
    dim = @img.dimension
    puts "- image is #{dim.width}x#{dim.height} pixels"
    num_slices, slice_width = determine_slice_params dim.width
    puts "- will shred into #{num_slices} slices, each #{slice_width} pixels wide"
    puts "TBD"
    puts "... processing done."
  end
  
  def output
    new_fname = @fname_orig.sub(/\.png\Z/, "_shredded.png")
    puts "Outputing image '#{new_fname}'..."
    puts "TBD"
    puts "... output done."
  end
private
  
  def determine_slice_params(total_width)
    # try for about 20 slices, go larger or smaller depending on image size
    size_ref = 35
    slice_count_ref = 20
    size = total_width / slice_count_ref
    if total_width % slice_count_ref == 0
      return slice_count_ref, size
    else
      if size < size_ref
        (slice_count_ref-1).downto(10).each do |count|
          return count, total_width / count if total_width % count == 0
        end
        raise "Unable to determine slice size downward"
      else
        (slice_count_ref+1).upto(40).each do |count|
          return count, total_width / count if total_width % count == 0
        end
        raise "Unable to determine slice size uwpard"
      end
    end
  end
  
end

puts "--- Image Shredder ---"
filename = ARGV[0]
unless filename
  puts "- you must specify a filename to shred"
  puts "  try: 'rake shred[filename]'"
  puts "   or: 'bundle exec ruby lib/image_shred.rb filename'"
  exit
end

begin
  is = ImageShred.new filename
  is.process
  is.output
rescue StandardError => err
  puts "- processing error: #{err.message}"
end

exit # DEBUG