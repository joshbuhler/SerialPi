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
		doPortThing()

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


}

public extension SerialPi {
	enum Error: Swift.Error {
		case missingFileName
		case failedToCreateFile
	}
}