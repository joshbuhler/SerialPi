puts("♦️ Starting echochamber")

# This will keep the script running until it's killed.
keepRunning = true
while keepRunning do
outputStr = ""
while line=STDIN.getc do
	outputStr << line
	#puts ("from ruby: #{line}")

	# puts("ruby: #{outputStr}")
	if (outputStr == "quit")
		puts("♦️ quitting\n")
		keepRunning = false
	end

	if (line == "\n")
		puts("♦️ endOfLine: #{outputStr}")
		break
	end
end
#puts("♦️ done")
end