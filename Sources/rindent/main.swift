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
	
	func fixed() -> String {
		let whitespacesPrefix = self.whitespacePrefix
		return whitespacesPrefix
			.components(separatedBy: "\t")
			.map({
				return String(repeating: "\t", count: $0.count / 4)
			})
			.joined(separator: "\t") + self[whitespacesPrefix.endIndex...]
		
	}
	
}

class FixCommand: Command {
	
	let name = "fix"
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
	
	func directory(forPath path: String?) -> URL {
		
		var directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
		
		if let pathUrl = path.map(URL.init(fileURLWithPath:)) {
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
		
		return directory
		
	}
	
	func inspect(file: URL) throws {
		let data = try String(contentsOf: file)
		let fixed = data.components(separatedBy: .newlines).map({ $0.fixed() }).joined(separator: "\n")
		if fixed != data {
			print("Fixing \(file.path)")
			try fixed.write(to: file, atomically: true, encoding: .utf8)
		}
	}
	
	func execute() throws {
		
		do {
			try self.findFiles(url: self.directory(forPath: self.path.value))
				.forEach(self.inspect(file:))
		} catch {
			print(error.localizedDescription)
			exit(1)
		}
		
	}
}

let inspecter = CLI(name: "fix")
inspecter.commands = [FixCommand()]

exit(inspecter.go())
