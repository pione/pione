
desc 'generate HTML API documentation'
task :html do
  sh "rdoc -x example -x test -x input -x output -x log.txt -f darkfish -o html"
end

desc 'count characters in input direcotry'
task :CountChar do
  sh "ruby -I lib bin/iw-stand-alone example/CountChar/CountChar.iw"
end
