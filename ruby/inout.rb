require 'open3'

# back-tick syntax
puts(`ls`)
puts(`echo "hi"`)


# using capture3 (requires open3)
stdout, stderr, status = Open3.capture3("ls")
puts("out: #{stdout}")
puts("err: #{stderr}")
puts("status: #{status}")

# using popen3 (also requires open3)
# Open3.popen3("uptime") do |stdin, stdout, stderr, thread|
# 	puts("popen3: #{stdout.read}")
# end

# Open3.popen3("sleep 2; ls") do |stdin, stdout, stderr, thread|
# 	while line=stdout.gets do
# 		puts ("line: #{line}")
# 	end
# end

while line=STDIN.gets do
	puts ("from STDIN: #{line}")
end