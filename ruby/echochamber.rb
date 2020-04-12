puts("♦️ Starting echochamber")

# Open3.popen3("sleep 2; ls") do |stdin, stdout, stderr, thread|
# 	while line=stdout.gets do
# 		puts ("line: #{line}")
# 	end
# end

# while line=STDIN.gets do
# 	puts ("from ruby: #{line}")
# end
keepRunning = true
while keepRunning do
outputStr = ""
while line=STDIN.getc do
	outputStr << line
	#puts ("from ruby: #{line}")

	# puts("ruby: #{outputStr}")
	if (outputStr == "quit")
		puts("quitting\n")
		keepRunning = false
	end

	if (line == "\n")
		puts("♦️ endOfLine: #{outputStr}")
		break
	end
end
#puts("♦️ done")
end