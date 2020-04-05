import SerialPiCore

let pi = SerialPi()

do {
	try pi.run()
} catch let error {
	print ("💩 - Error: \(error)")
}