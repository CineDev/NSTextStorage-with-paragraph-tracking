//
//  ParagraphDescriptor.swift
//  Core
//
//  Created by Vitaliy Vashchenko on 8/31/17.
//  Copyright © 2017 Cine Studio. All rights reserved.
//

import Foundation

public struct ParagraphDescriptor: Equatable {
	/// Unique identifier of the paragraph
	public let identifier: UUID
	
	/// Range of the paragraph
	public var range: NSRange
	
	public static func ==(lhs: ParagraphDescriptor, rhs: ParagraphDescriptor) -> Bool {
		return lhs.identifier == rhs.identifier
	}
	
	init(identifier: UUID = UUID(), range: NSRange = NSRange(value: 0)) {
		self.identifier = identifier
		self.range = range
	}
}
