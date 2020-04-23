import Foundation
import Files
import SwiftSerial

public final class SerialPi {
	private let arguments:[String]

	public init(arguments:[String] = CommandLine.arguments) {
		self.arguments = arguments
	}

	public func run() throws {
		print ("Hey Howdy Hey!")
		guard arguments.count > 1 else {
			throw Error.missingArgument
		}

		let thing = arguments[1]
		switch thing {
			case "file":
				let filename = arguments[2]
				try? doFileThing(name: filename)
			case "port":
				doPortThing()
			case "process":
				doProcessThing()
			case "process2":
				doProcessThing2()
			case "ruby":
				doRubyThing()
			case "ping":
				doPingThing()
			case "listen":
				doListenThing()
			case "call":
				doCallThing()
			case "kiss":
				doKissThing()
			case "pipe":
				doPipeThing()
			default:
				print("Not a valid option. ( file [filename] | port | process | ruby )")

		}
	}

	/**
	Creates an empty file. From the tutorial I followed when setting this up.
	(see README)
	*/
	func doFileThing(name:String) throws {
		print ("📂  doFileThing")

		do {
			try Folder.current.createFile(at: name)
		} catch {
			throw Error.failedToCreateFile
		}
	}

	// Messing with sending data to the same port normally bound by kissattach.
	// Looks like if the port is bound though, I can't write to it.
	func doPortThing () {
		print ("🛳  doPortThing")

		let serialPort:SerialPort = SerialPort(path: "/dev/ttyAMA0")
		
		do {
			try serialPort.openPort()
		} catch let error {
			print ("Failed to open serial port: \(error)")
		}

		serialPort.setSettings(receiveRate: .baud9600,
			transmitRate: .baud9600,
			minimumBytesToRead: 1)

		do {
			let bytesWritten = try serialPort.writeString("Testing from Swift")
			print ("bytesWritten: \(bytesWritten)")
			} catch let error {
				print ("error writing to port: \(error)")
			}

	}

	/** 
	Using Process and Pipe. Want to try writing & reading via stdin/stdout.
	Process compiles/runs fine on Pi, but on macOS get complaints about
	availability of different properties. Not 100% sure why the code here runs
	fine on the Pi, but barfs on macOS.
	*/
	func doProcessThing() {
		print ("⚙️  doProcessThing")

		if #available(macOS 10.13, *) {
			let fl = Process()
			// Use fileURLWithPath - not URL(string:)
			//fl.executableURL = URL(fileURLWithPath:"/usr/local/bin/fastlane")
			fl.executableURL = URL(fileURLWithPath:"/bin/ls")
			//fl.executableURL = URL(fileURLWithPath:"/usr/bin/axcall")
			fl.arguments = ["-la"]
			
			let pipe = Pipe()

			fl.standardOutput = pipe

			do {
				try fl.run()
				let data = pipe.fileHandleForReading.readDataToEndOfFile()
				if let output = String(data: data, encoding:String.Encoding.utf8) {
					print("Output: \(output)")

				}
			} catch {
				print ("derp")
			}
		}
	}

	var buildTask:Process!
	func doProcessThing2() {
		print ("⚙️  doProcessThing2")

		if #available(macOS 10.13, *) {
			let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
			taskQueue.async { [weak self] in
				
				self?.buildTask = Process()
				self?.buildTask.executableURL = URL(fileURLWithPath:"/usr/bin/ruby")
				self?.buildTask.arguments = ["./ruby/echo2.rb"]
				self?.buildTask.terminationHandler = { (process) in 
					print ("terminationHandler")
					exit(0)
				}

				if let task = self?.buildTask {
					self?.captureOutput(proc: task)
				}

				try? self?.buildTask.run()
				self?.buildTask.waitUntilExit()
			}
		}
	}

	var outPipe:Pipe!
	func captureOutput (proc:Process) {
		outPipe = Pipe()
		proc.standardOutput = outPipe

		outPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

		let nc = NotificationCenter.default
		nc.addObserver(forName: Notification.Name.NSFileHandleDataAvailable,
			object: outPipe.fileHandleForReading,
			queue: nil) { [weak self] n in

			if let output = self?.outPipe.fileHandleForReading.availableData {
				let outString = String(data: output, encoding: String.Encoding.utf8) ?? "noData"
				print ("outString: \(outString)")
				self?.outPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
			}
		}
	}

	func doRubyThing() {
		print ("🐦 Doing rubyThing")
		
		if #available(macOS 10.15, *) {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath:"/usr/bin/ruby")
			proc.arguments = ["./ruby/echochamber.rb"]
			
			let inPipe = Pipe()
			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
			
				let data = fileHandle.availableData
				if let string = String(data: data, encoding: String.Encoding.utf8) {
					print ("🐦 running: \(proc.isRunning) read (\(data.count)): \(string)")
					if (string.isEmpty || !proc.isRunning) {
						exit(0)
					}

					// <debugging>
					// this will print out all characters received for debuggin
					string.unicodeScalars.map {
						print ("char: \($0.escaped(asASCII: true))")
					}

					// if let lastChar = string.last {
					// 	print ("lastChar: \(lastChar == "\n")")
					// 	// everything coming in end with a line break?
					// }
					// </debugging>

					self?.waitForInput()
				}
			}

			self.outPipe = Pipe()
			// let outFile = fdopen(outPipe.fileHandleForWriting.fileDescriptor, "w")
			proc.standardOutput = inPipe
			proc.standardInput = outPipe

			proc.terminationHandler = { (process) in 
				print ("🐦 terminationHandler")
				exit(0)
			}

			do {
				try proc.run()
				// proc.waitUntilExit() // using terminationHandler this isn't needed. Keeping for reference.
			} catch {
				print ("🐦 derp")
			}
		}
	}

	func waitForInput () {
		print ("🐦 >:")
		// need to be sure to strip the newline, otherwise stuff doesn't get written to the pipe
		if let outString = readLine(strippingNewline: false) {
			if let outData = outString.data(using: .utf8) {
				print("🐦 writing: \(outString)\n")
				outPipe.fileHandleForWriting.write(outData)
				// fflush(stdout)
			}
		}
	}

	func doPingThing() {
		print ("🐦 Doing pingThing")
		// sleep(2)
		// print ("Awake")
		if #available(macOS 10.13, *) {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath:"/sbin/ping")

			print ("Ping who?")
			if let ipAddress = readLine(strippingNewline: true) {

				//proc.arguments = ["192.168.1.99"]
				proc.arguments = ["\(ipAddress)"]
			}
			
			let inPipe = Pipe()
			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
			
				let data = fileHandle.availableData
				if let string = String(data: data, encoding: String.Encoding.utf8) {
					if (string.isEmpty) {
						exit(0)
					}
					print ("🐦 readHandler: \(string)")
				}
			}

			proc.standardOutput = inPipe

			do {
				try proc.run()
				proc.waitUntilExit()
			} catch {
				print ("🐦 derp")
			}
		}
	}

	func doListenThing() {
		print ("🐦 Doing listenThing")
		
		if #available(macOS 10.13, *) {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath:"/usr/bin/axlisten")
			proc.arguments = ["-a"]
			
			let inPipe = Pipe()
			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
			
				let data = fileHandle.availableData
				if let string = String(data: data, encoding: String.Encoding.utf8) {
					if (string.isEmpty) {
						exit(0)
					}
					print ("🐦 readHandler: \(string)")
				}
			}

			proc.standardOutput = inPipe

			do {
				try proc.run()
				proc.waitUntilExit()
			} catch {
				print ("🐦 derp")
			}
		}
	}

	func doCallThing() {
		print ("🐦 Doing callThing")
		
		if #available(macOS 10.13, *) {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath:"/usr/bin/axcall")
			proc.arguments = ["-s", "kc6bsa", "3", "ac7br-4", "-r"]
			// https://manpages.ubuntu.com/manpages/trusty/man1/axcall.1.html
			// -s kc6bsa	|| the call being used
			// 3			|| port to use, defined in /etc/ax25/axports
			// ac7br-4		|| the callsign being called
			// -r 			|| use Raw mode (no window being presented)
			//
			// slave mode (-h) doesn't appear to be what we want here
			
			let inPipe = Pipe()
			let outPipe = Pipe()

			proc.standardOutput = inPipe
			proc.standardInput = outPipe

			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
			
				let data = fileHandle.availableData
				if let string = String(data: data, encoding: String.Encoding.utf8) {
					// if (string.isEmpty) {
					// 	exit(0)
					// }
					print ("🐦 response (\(string.count)): \(string)")

					if (string.count == 0) {
						print ("cmd:")
						if let cmd = readLine(strippingNewline: true),
							let outData = cmd.data(using: .utf8) {
							print("🐦 sending: \(cmd)\n")
							let handle = outPipe.fileHandleForWriting
							handle.write(outData)
							fflush(nil)
						}
					}
				}
			}

			do {
				try proc.run()
				proc.waitUntilExit()
			} catch {
				print ("🐦 derp")
				exit(1)
			}
		}
	}

	func doKissThing() {
		print ("🐦 Doing kissThing")

		if #available(macOS 10.13, *) {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath:"/usr/sbin/kissattach")
			proc.arguments = ["/dev/ttyAMA0", "3", "10.1.1.1"]
			
			let inPipe = Pipe()
			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
			
				let data = fileHandle.availableData
				if let string = String(data: data, encoding: String.Encoding.utf8) {
					if (string.isEmpty) {
						exit(0)
					}
					print ("🐦 readHandler: \(string)")
				}
			}

			proc.standardOutput = inPipe

			do {
				try proc.run()
				proc.waitUntilExit()
			} catch {
				print ("🐦 derp")
			}
		}
	}

	func doPipeThing() {
		print ("🐦 Doing pipeThing")
		
		if #available(macOS 10.13, *) {


			let inPipe = Pipe()
			let outPipe = Pipe()

			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
				let data = fileHandle.availableData
				if (data.isEmpty) {
					return
				}
				print ("inPipe reading")
				print ("data: \(data.count) isEmpty: \(data.isEmpty)")
				// if let string = String(data: data, encoding: String.Encoding.utf8) {
				// 	if (string.isEmpty) {
				// 		exit(0)
				// 	}
				// 	print ("🐦 readHandler: \(string)")
				// }
			}

			outPipe.fileHandleForWriting.writeabilityHandler = { [weak self] fileHandle in
				// let data = fileHandle.availableData
				// if (data.isEmpty) {
				// 	return
				// }
				print ("outpipe reading")
				// print ("data: \(data.count) isEmpty: \(data.isEmpty)")
				// if let string = String(data: data, encoding: String.Encoding.utf8) {
				// 	if (string.isEmpty) {
				// 		exit(0)
				// 	}
				// 	print ("🐦 outPipe handler: \(string)")
				// }
			}

			outPipe.fileHandleForWriting.write("blah".data(using: .utf8)!)

			// if let outString = readLine(strippingNewline: true) {
			// 	if let outData = outString.data(using: .utf8) {
			// 		print("🐦 writing: \(outString)")
			// 		outPipe.fileHandleForWriting.write(outData)
			// 		// fflush(outFile)
			// 		sleep(1)
			// 	}
			// }
		}
	}
}

public extension SerialPi {
	enum Error: Swift.Error {
		case missingFilename
		case failedToCreateFile
		case missingArgument
	}
}
