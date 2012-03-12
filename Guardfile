# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'coffeescript', :output => 'build' do
    watch(%r{^src/(.+\.coffee)})
end
guard 'coffeescript', :output => '.' do
    watch(%r{^([^/]+\.coffee)})
    watch(%r{^(spec-fixtures.*.coffee)})
end
