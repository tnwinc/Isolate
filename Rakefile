root=File.dirname __FILE__

task :default => [:build]
task :build do
  system("cd #{root} && coffee --compile --output build/ src/")
  system("cd #{root} && coffee --compile bootstrap.coffee")
end

task :test => [:build] do
  system "cd #{root} && NODE_PATH=./build:.:$NODE_PATH mocha -r bootstrap.js --reporter spec ./src/*.spec.coffee"
end

task :clean do
  system "cd #{root} && rm -rf ./build ./bootstrap.js"
end
