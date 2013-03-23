root=File.dirname __FILE__
npm_bin=`npm bin`.strip!

task :default => [:build]

def run(cmd)
  puts cmd
  output = `#{cmd}`
  print output
  return output
end

desc 'Create js files from coffee sources'
task :build do
  Dir.chdir root do
    run "#{npm_bin}/coffee --compile --output . src/isolate.coffee"
    run "#{npm_bin}/coffee --compile spec"
  end
end

test_namespace = namespace :test do
  desc "Verify Isolate usage under node's version of require"
  task :commonjs => :build do
    debug = isDebug?() ? ' debug' : ''
    Dir.chdir root do
      ENV["NODE_PATH"] = ".:./spec:./spec/modules_for_testing/commonjs:#{ENV["NODE_PATH"]}"
      run "#{npm_bin}/mocha --compilers coffee:coffee-script --reporter spec #{debug} ./spec/commonjs.spec.coffee"
    end
  end

  desc "Verify Isolate usage under requirejs's version of require"
  task :requirejs => :build do
    versions = ENV['versions'] || ENV['version'] || 'latest'
    debug = isDebug?() ? ' debug' : ''
    supportedVersionsRegex = Regexp.new("^2\.[0-9]\.[0-9]$")

    all_versions = `npm view requirejs versions | grep -oE [0-9.]+`.split

    case versions
    when 'all'
      versions_to_test_against = all_versions
    when 'supported'
      versions_to_test_against = all_versions.keep_if { |v| supportedVersionsRegex.match(v) }
    when 'latest'
      versions_to_test_against = [ all_versions.last ]
    else
      raise('versions argument not understood. Must be one of "all", "supported", "latest", or glob: "2.x.x", "2.1.x", or "2.1.1"') unless /^([0-9]+|x)\.([0-9]+|x)\.([0-9]+|x)$/.match versions
      regex = Regexp.new("^#{versions.gsub('.', '\\.').gsub('x','[0-9]')}$")
      versions_to_test_against = all_versions.keep_if { |v| regex.match(v) }
    end

    puts "testing against versions: [#{versions_to_test_against}]"

    versions_to_test_against.each do |version|
      Dir.chdir root do
        puts "Running tests against requirejs version: [#{version}]"
        run "npm install requirejs@#{version}"
        ENV["NODE_PATH"] = ".:./spec:#{ENV["NODE_PATH"]}"
        cmd = "#{npm_bin}/mocha --compilers coffee:coffee-script --globals 'define,requirejsVars' --reporter spec #{debug} ./spec/requirejs.spec.coffee"
        if isDebug?()
          system cmd
        else
          tests_output = run cmd
          raise('Failed to load Tests') if tests_output.include? '0 tests complete'
          tests_passed = $?.success?
          raise('Tests Failed') unless tests_passed
        end
      end
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
