public extension String {
	/// Array of lines of the string. Line is a standalone string without 'new line' character
	public var lines: [String] {
		return self.components(separatedBy: .newlines)
	}
	
	/// Array of paragraphs of the string. Each paragraph except the last one ends with the 'newline' character
	public var paragraphs: [String] {
		var paragraphs = self.lines
		for i in 0 ..< paragraphs.count {
			if i != paragraphs.count - 1 {
				paragraphs[i] += "\n"
			}
		}
		return paragraphs
	}
}
