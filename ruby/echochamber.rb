puts("♦️ Starting echochamber")
STDOUT.flush

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
		puts("♦️ #{outputStr}")
		STDOUT.flush
		sleep(1)
		break
	end
end
#puts("♦️ done")
end