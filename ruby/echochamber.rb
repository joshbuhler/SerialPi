puts("♦️ Starting echochamber")
STDOUT.flush

# This will keep the script running until it's killed.
keepRunning = true
while keepRunning do
outputStr = ""
while char=STDIN.getc do
	outputStr << char
	puts ("♦️ char: #{char}")

	# puts("ruby: #{outputStr}")
	if (outputStr == "quit")
		puts("♦️ quitting\n")
		keepRunning = false
		STDOUT.flush

		puts("\n")
		STDOUT.flush
		break
	end

	if (char == "\n")
		puts("♦️ #{outputStr}")
		STDOUT.flush
		break
	end
end
#puts("♦️ done")
end