root=File.dirname __FILE__
task :test do

  system "cd #{root} && NODE_PATH=./build:.:$NODE_PATH mocha -r bootstrap.js --reporter spec ./src/*.spec.coffee"

end
