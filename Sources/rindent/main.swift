import SwiftCLI
import Foundation

extension Array {
	
	func some(_ filter: (Element) -> Bool) -> Bool {
		return self.first(where: filter) != nil
	}
	
}

extension String {
	
	private var whitespacePrefix: String {
		var currentIndex = self.startIndex
		var result = ""
		while currentIndex != self.endIndex && CharacterSet.whitespaces.contains(self[currentIndex].unicodeScalars.first!) {
			result += String(self[currentIndex])
			currentIndex = self.index(currentIndex, offsetBy: 1)
		}
		if result.hasPrefix("\t") {
			result = result
				// We do allow spaces at the end of the indentation for alignment purposes.
				.replacingOccurrences(of: " +$", with: "", options: .regularExpression)
		}
		return result
	}
	
	func inspectIndentation() -> Int? {
		guard let index = self.whitespacePrefix.rangeOfCharacter(from: CharacterSet(charactersIn: "\t").inverted)
			else { return nil }
		return self.distance(from: self.startIndex, to: index.lowerBound)
	}
	
}

class InspectCommand: Command {
	
	let name = "inspect"
	let path = OptionalParameter()
	let ignore = OptionalCollectedParameter()
	
	private lazy var ignoredUrls: [URL] = {
		return self.ignore.value.map({ URL(fileURLWithPath: $0) })
	}()
	
	func findFiles(url: URL) -> [URL] {
		
		guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) else {
			return []
		}
		
		return urls
			.compactMap({ (url) -> [URL]? in
				var isDirectory: ObjCBool = false
				_ = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
				guard !isDirectory.boolValue else {
					return findFiles(url: url)
				}
				guard url.pathExtension == "swift" else {
					return nil
				}
				return [url]
			})
			.reduce([], +)
			.filter({ (url) -> Bool in
				return !self.ignoredUrls.some({ (ignoreUrl) in
					return url.path.hasPrefix(ignoreUrl.path)
				})
			})
		
	}
	
	///Users/trenskow/Desktop/rindent/Sources/rindent/main.swift:26:100: error: expected '{' after 'if' condition
	func inspect(file: URL) throws {
		let data = try String(contentsOf: file)
		let lines = data.components(separatedBy: .newlines)
		lines.enumerated().forEach { (line) in
			if let characterPos = line.element.inspectIndentation() {
				print("\(file.path):\(line.offset):\(characterPos): warning: Disallowed indentation character.")
			}
		}
	}
	
	func execute() throws {
		
		var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
		
		if let pathUrl = path.value.map(URL.init(fileURLWithPath:)) {
			directory = pathUrl
		}
		
		var isDirectory: ObjCBool = false
		
		guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) else {
			print("Directory not found")
			exit(1)
		}
		
		guard isDirectory.boolValue else {
			print("Not a directory")
			exit(1)
		}
		
		do {
			try self.findFiles(url: directory)
				.forEach(self.inspect(file:))
		} catch {
			print(error.localizedDescription)
			exit(1)
		}
		
	}
}

let inspecter = CLI(name: "inspect")
inspecter.commands = [InspectCommand()]

exit(inspecter.go())
