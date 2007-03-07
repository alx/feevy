##
# Run a single test in Rails.
#
#   rake blogs_list
#   => Runs test_list for BlogsController (functional test)
#
#   rake blog_create
#   => Runs test_create for BlogTest (unit test)

rule "" do |t|
  if /test:(.*)(:([^.]+))?$/.match(t.name)
    arguments = t.name.split(":")[1..-1]
    file_name = arguments.first
    test_name = arguments[1..-1]
    
    if File.exist?("test/unit/#{file_name}_test.rb")
      run_file_name = "unit/#{file_name}_test.rb" 
    elsif File.exist?("test/functional/#{file_name}_controller_test.rb")
      run_file_name = "functional/#{file_name}_controller_test.rb" 
    elsif File.exist?("test/functional/#{file_name}_test.rb")
      run_file_name = "functional/#{file_name}_test.rb" 
    end
    
    sh "ruby -Ilib:test test/#{run_file_name} -n /#{test_name}/" 
  end
end