root=File.dirname __FILE__

task :default => [:build]
task :build do
  system("cd #{root} && coffee --compile --output . src/isolate.coffee")
  system("cd #{root} && coffee --compile spec")
end

test_namespace = namespace :test do
  task :commonjs => [:build] do
    puts 'testing: commonjs'
    #system "cd #{root} && NODE_PATH=.:$NODE_PATH mocha --compilers coffee:coffee-script -r ./spec/commonjs/bootstrap.js --reporter spec ./spec/commonjs/*.spec.coffee"
  end

  task :requirejs => [:build] do
    puts 'testing: requirejs'
    #system "cd #{root} && NODE_PATH=.:$NODE_PATH mocha --compilers coffee:coffee-script -r ./spec/requirejs/bootstrap.js --globals 'define,requirejsVars' --reporter spec ./spec/requirejs/*.spec.coffee"
  end
end

task :test do
  test_namespace.tasks.each {|test_task| test_task.invoke}
end

task :clean do
  system "cd #{root} && rm -rf ./isolate.js src/**/*.js spec/**/*.js"
end
