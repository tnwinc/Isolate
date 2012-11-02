root=File.dirname __FILE__

task :default => [:build]

desc 'Create js files from coffee sources'
task :build do
  system("cd #{root} && coffee --compile --output . src/isolate.coffee")
  system("cd #{root} && coffee --compile spec")
end

test_namespace = namespace :test do
  desc "Verify Isolate usage under node's version of require"
  task :commonjs => [:build] do
    debug = isDebug?() ? ' debug' : ''
    Dir.chdir root do
      system "NODE_PATH=.:./spec:./spec/modules_for_testing/commonjs:$NODE_PATH mocha --compilers coffee:coffee-script --reporter spec #{debug} ./spec/commonjs.spec.coffee"
    end
  end

  desc "Verify Isolate usage under requirejs's version of require"
  task :requirejs => [:build] do
    debug = isDebug?() ? ' debug' : ''
    Dir.chdir root do
      system "NODE_PATH=.:./spec:$NODE_PATH mocha --compilers coffee:coffee-script --globals 'define,requirejsVars' --reporter spec #{debug} ./spec/requirejs.spec.coffee"
    end
  end
end

desc 'Verify Isolate usage'
task :test do
  test_namespace.tasks.each {|test_task| test_task.invoke}
end

desc 'Remove built js files'
task :clean do
  Dir.chdir root do
    FileUtils.rm(FileList['*.js'])
    FileUtils.rm(FileList['spec/**/*.js'])
  end
end

# noop for syntactic sugar
task :debug

def isDebug?
  ARGV[1..-1].include?('debug')
end
