import Foundation
import SerialPiCore

// https://www.swiftbysundell.com/articles/building-a-command-line-tool-using-the-swift-package-manager/
// Installing:
// - swift build -c release
// - cd .build/release
// - cp -f SerialPi /usr/local/bin/serialpi

let pi = SerialPi()

do {
	try pi.run()
} catch let error {
	print ("💩 - Error: \(error)")
}

RunLoop.main.run()