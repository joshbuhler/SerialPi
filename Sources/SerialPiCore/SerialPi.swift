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
		// guard arguments.count > 1 else {
		// 	throw Error.missingFileName
		// }

		// let fileName = arguments[1]

		// do {
		// 	try Folder.current.createFile(at: fileName)
		// } catch {
		// 	throw Error.failedToCreateFile
		// }
		// doPortThing()
		fastlane()

	}

	func doPortThing () {
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

	func fastlane() {
		let fl = Process()
		// fl.executableURL = URL(string:"/usr/local/bin/fastlane")

		var pipe = Pipe()

		fl.standardOutput = pipe

		do {
			// try fl.run()
			let data = pipe.fileHandleForReading.readDataToEndOfFile()
			if let output = String(data: data, encoding:String.Encoding.utf8) {
				print("Output: \(output)")
			}
		} catch {
			print ("derp")
		}
	}


}

public extension SerialPi {
	enum Error: Swift.Error {
		case missingFileName
		case failedToCreateFile
	}
}