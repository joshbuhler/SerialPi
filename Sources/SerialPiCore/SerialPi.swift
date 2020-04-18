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
				doProcessThing2()
			case "ruby":
				doRubyThing()
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
			taskQueue.async {
				Thread.sleep(forTimeInterval: 2.0)
				print ("async")

				self.buildTask = Process()
				self.buildTask.executableURL = URL(fileURLWithPath:"/usr/bin/ruby")
				self.buildTask.arguments = ["./ruby/echo2.rb"]
				self.buildTask.terminationHandler = { (process) in 
					print ("terminationHandler")
					exit(0)
				}

				try? self.buildTask.run()
				self.buildTask.waitUntilExit()
			}
		}
	}

	// func captureOutput (proc:Process)

	func doRubyThing() {
		print ("🐦 Doing rubyThing")
		// sleep(2)
		// print ("Awake")
		if #available(macOS 10.13, *) {
			let proc = Process()
			proc.executableURL = URL(fileURLWithPath:"/usr/bin/ruby")
			proc.arguments = ["./ruby/echochamber.rb"]
			
			let inPipe = Pipe()
			inPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
			
				let data = fileHandle.availableData
				if let string = String(data: data, encoding: String.Encoding.utf8) {
					print ("🐦 string: \(string)")
					exit(0)
				}
			}

			let outPipe = Pipe()

			proc.standardOutput = inPipe
			proc.standardInput = outPipe

			do {
				try proc.run()
				let lines = ["🐦 Swift says hello.\n",
								"line 2\n",
								"line 3\n",
								"quit"]
								// "\n"]

				for line in lines {
					let outString = line
					if let outData = outString.data(using: .utf8) {
						print("🐦 writing outData\n")
						outPipe.fileHandleForWriting.write(outData)
					}
				}
				outPipe.fileHandleForWriting.closeFile()

				// Looks like we can have a readabilityHandler or read available data, but not both
				// let data = inPipe.fileHandleForReading.availableData
				// // let data = pipe.fileHandleForReading.readData(ofLength: 10)
				// if let output = String(data: data, encoding:String.Encoding.utf8) {
				// 	print("🐦 Output: \(output)")
				// }
			} catch {
				print ("🐦 derp")
			}
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
