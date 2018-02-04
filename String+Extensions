public extension String {
	/// Array of paragraphs of the string. Each paragraph except the last one ends with 'new line' character
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
