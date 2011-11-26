desc "`rake` will default to running the app"
task :default => :unshred

#desc "Run all the rspec examples"
#task :spec do
#  system "bundle exec rspec -c spec/*_spec.rb"
#end

desc "Run the 'unshred' app"
task :unshred, :filename, :slice_width do |t, args|
  filename = args[:filename]
  slice_width = args[:slice_width]
  system "bundle exec ruby lib/image_unshred.rb '#{filename}' #{slice_width}"
end

desc "Run the shred app"
task :shred, :filename do |t, args|
  filename = args[:filename]
  system "bundle exec ruby lib/image_shred.rb '#{filename}'"
end

desc "Run unshred on all shredded files"
task :unshred_all do
  shredded_files = FileList.new('data/*_shredded(*pxl).png')
  shredded_files.each do |filename|
    slice_width = filename[/\((\d+)pxl\).png/, 1]
    puts "#{filename}, #{slice_width}"
    Rake::Task["unshred"].execute({:filename => filename, :slice_width => slice_width})
  end
end

desc "Remove all partials"
task :clean_partials do
  FileList.new('data/*_partial_*.png').each do |partial|
    sh 'rm', partial
  end
end
desc "Remove all final unshredded files"
task :clean_finals do
  FileList.new('data/*)_unshredded.png').each do |final|
    sh 'rm', final
  end
end
desc "Remove all unshred products"
task :clean => [:clean_finals, :clean_partials]
