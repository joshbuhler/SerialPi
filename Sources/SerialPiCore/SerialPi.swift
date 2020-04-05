import Foundation
import Files

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
	}
}

public extension SerialPi {
	enum Error: Swift.Error {
		case missingFileName
		case failedToCreateFile
	}
}