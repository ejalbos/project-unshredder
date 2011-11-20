desc "`rake` will default to running the app"
task :default => :unshred

#desc "Run all the rspec examples"
#task :spec do
#  system "bundle exec rspec -c spec/*_spec.rb"
#end

desc "Run the 'unshred' app"
task :unshred do
  system "bundle exec ruby lib/image_unshred.rb"
end

desc "Run the shred app - NOT YET IMPLEMENTED"
task :shred do
  system "bundle exec ruby lib/image_shred.rb"
end
