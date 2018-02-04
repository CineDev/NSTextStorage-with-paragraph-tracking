//
//  DescriptiveTextStorage.swift
//  Core: Text Engine
//
//  Created by Vitaliy Vashchenko on 2/2/18.
//  Copyright © 2018 Cine Studio. All rights reserved.
//
//
//  DescriptedTextStorage is a subclass of NSTextStorage class.
//  It works with whole paragraphs of text and notifies its	paragraph delegate
//  if user changes any paragraphs. Delegate receives touched paragraph descriptors.
//
//  This behavior is important when any paragraph represents a specific object
//  in your model. So, every single change to the text storage will be	reflected
//. in the appropriate object of your model.
//
//  As a result, now you get an opportunity to track changes by paragraph
//  and reflect those changes to your model and make it easy to persist with, let's say, Core Data.

#if (os(iOS))
	import UIKit
#else
	import AppKit
#endif

/// Protocol defines methods that are invoked if the storage has been edited
public protocol DescriptedTextStorageDelegate: class {
	func textStorage(_ textStorage: DescriptedTextStorage, didAdd paragraphDescriptor: ParagraphDescriptor)
	func textStorage(_ textStorage: DescriptedTextStorage, willDelete paragraphDescriptor: ParagraphDescriptor)
	func textStorage(_ textStorage: DescriptedTextStorage, didEdit paragraphDescriptor: ParagraphDescriptor)
	func textStorage(_ textStorage: DescriptedTextStorage, shouldSetStyleFor paragraphDescriptor: ParagraphDescriptor) -> [NSAttributedStringKey: Any]?
}

public class DescriptedTextStorage: NSTextStorage {
	
	public enum SubstringConsistency {
		case exact
		case dropLastEmptyParagraph
		case includeLastEmptyParagraph
	}

	
	//MARK: - Properties
	
	/// Backing storage of the text string
	private let storage = NSMutableAttributedString()
	
	private var _paragraphDescriptors = [ParagraphDescriptor]()
	
	public var paragraphDescriptors: [ParagraphDescriptor] {
		return self._paragraphDescriptors
	}
	
	/// Delegate watches for any edits in the storage
	public weak var paragraphDelegate : DescriptedTextStorageDelegate?
	
	private var needsFixDescriptors: Bool = false
	
	/// Text storage with read-only access
	override public var string : String {
		return self.storage.mutableString as String
	}
	
	public override var length: Int {
		return self.storage.length
	}
	
	public override var fixesAttributesLazily: Bool {
		return false
	}

	public override init() {
		super.init()
		
		// any text storage has at least one paragraph
		self._paragraphDescriptors.append(ParagraphDescriptor())
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		// any text storage has at least one paragraph
		self._paragraphDescriptors.append(ParagraphDescriptor())
	}
	
	#if os(OSX)
	required public init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
		super.init(pasteboardPropertyList: propertyList, ofType: type)
		
		// any text storage has at least one paragraph
		self._paragraphDescriptors.append(ParagraphDescriptor())
	}
	#endif
	
	
	// MARK: - String Processing
	
	public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedStringKey : Any] {
		guard self.length > 0 else {
			return [:]
		}
		if location == self.length, location > 0 {
			return self.storage.attributes(at: location - 1, effectiveRange: range)
		}
		return self.storage.attributes(at: location, effectiveRange: range)
	}
	
	private var beforeParagraphs: [String] = []
	
	
	override public func replaceCharacters(in range: NSRange, with str: String) {
		self.needsFixDescriptors = true
		
		// cache the substring with its paragraphs before the editing
		let beforeString = String(self.string[Range(range, in: self.string)!])
		self.beforeParagraphs = beforeString.paragraphs
		
		// make the edit
		self.beginEditing()
		self.storage.replaceCharacters(in: range, with: str)
		self.edited([.editedCharacters, .editedAttributes], range: range, changeInLength: str.utf16.count - range.length)
		self.endEditing()
	}
	
	
	override public func setAttributes(_ attrs: [NSAttributedStringKey : Any]!, range: NSRange) {
		defer {
			self.edited(.editedAttributes, range: range, changeInLength: 0)
		}
		
		var attributes = attrs!
		
		// if descriptors are already fixing, skip descriptors checking
		if self.needsFixDescriptors {
			self.storage.setAttributes(attributes, range: range)
			return
		}
		
		// otherwise make sure that any new attributes coming to the storage
		// will have appropriate paragraph identifiers
		let descriptors = self.paragraphDescriptors(in: range)
		
		guard !descriptors.isEmpty else {
			assertionFailure("Descriptors not found in range \(range)")
			return
		}
		
		// set an appropriate identifier to the range of every paragraph in the given range
		for descriptor in descriptors {
			attributes[.identifier] = descriptor.identifier
			self.storage.setAttributes(attributes, range: descriptor.range)
		}
	}

	
	// MARK: - Attributes Management
	
	/**
	Override to make sure that correct paragraph attributes are spread through the whole paragraph
	- parameter range: range which might have an inconsistent attribute state
	*/
	public override func fixAttributes(in range: NSRange) {
		super.fixAttributes(in: range)
		
		if self.needsFixDescriptors {
			self.fixParagraphDescriptors(in: range)
		}

		guard range.length > 0 else { return }
		let descriptors = self.paragraphDescriptors(in: range)
		
		for descriptor in descriptors {
			
			// search for partial completion attributes first
			self.enumerateAttributes(in: descriptor.range, options: .reverse, using: {
				[weak self] (attributes, range, stop) in
				guard let selfInstance = self else { return }
				
				// if the delegate want to set new attributes for the paragraph descriptor, set it
				if let attributes = selfInstance.paragraphDelegate?.textStorage(selfInstance, shouldSetStyleFor: descriptor) {
					selfInstance.beginEditing()
					selfInstance.setAttributes(attributes, range: descriptor.range)
					selfInstance.endEditing()
				}
			})
		}
	}
	
	
	
	// MARK: - Paragraph Descriptors
	
	private func fixParagraphDescriptors(in range: NSRange) {
		// calculate paragraph ranges after editing
		var paragraphsAfter = self.substringParagraphRanges(in: range, consistency: .includeLastEmptyParagraph)
		
		// get the after the editing substring and break it into the paragraphs
		let afterString = String(self.string[Range(self.editedRange, in: self.string)!])
		let afterParagraphs = afterString.paragraphs
		
		// now compare paragraphs before and after editing and calculate changes
		let addedParagraphs = afterParagraphs.dropFirst(self.beforeParagraphs.count).count
		let deletedParagraphs = self.beforeParagraphs.dropFirst(afterParagraphs.count).count
		let editedParagraphs = afterParagraphs.dropLast(addedParagraphs).count
		
		var delta = 0
		
		// first, get the first edited descriptor since it's the ancor for any forthcoming opeations
		let firstEditedDescriptor = self.paragraphDescriptor(atCharacterIndex: editedRange.location)
		let firstEditedIndex = self.paragraphDescriptors.index(of: firstEditedDescriptor)!
		
		// delete paragraphs by offset from the first edited paragraph
		for _ in 0 ..< deletedParagraphs {
			let index = firstEditedIndex + 1
			delta += self.deleteDescriptor(at: index)
		}
		
		// edit paragraphs by offset from the first edited paragraph
		for i in 0 ..< editedParagraphs {
			// ranges for edited paragraphs holds the array with after editing ranges
			let editedRange = paragraphsAfter[i]
			let index = firstEditedIndex + i
			delta += self.editDescriptor(at: index, newRange: editedRange)
		}
		
		// ranges for edited paragraphs holds the array with after editing ranges
		let addedRanges = Array(paragraphsAfter.dropFirst(editedParagraphs))
		
		// add paragraphs by offset from the first edited paragraph
		for i in 0 ..< addedParagraphs {
			let addedRange = addedRanges[i]
			let index = firstEditedIndex + i + 1
			delta += self.addDescriptor(at: index, range: addedRange)
		}
		
		// get the paragraph index from which we'll start the offset
		// of locations of every range following the index where changes were made
		let startIndex = firstEditedIndex + addedParagraphs
		
		// update the cache
		if startIndex < self.paragraphDescriptors.count - 1 {
			self.updateDescriptorLocations(from: startIndex, delta: delta)
		}
		
		self.beforeParagraphs.removeAll()
		self.needsFixDescriptors = false
	}
	
	public func paragraphDescriptor(atParagraphIndex index: Int) -> ParagraphDescriptor {
		return self.paragraphDescriptors[index]
	}

	public func paragraphDescriptor(atCharacterIndex characterIndex: Int) -> ParagraphDescriptor {
		if self.length == 0 && characterIndex == 0 || characterIndex == 0 {
			return self.paragraphDescriptors.first!
		}
		
		if characterIndex == self.length && self.paragraphDescriptors.last?.range.max == self.length ||
			characterIndex == self.paragraphDescriptors.last?.range.max {
			return self.paragraphDescriptors.last!
		}
		
		if let descriptor = self.paragraphDescriptors.filter({ $0.range.contains(characterIndex) }).first {
			return descriptor
		}
		
		let identifier = self.attribute(.identifier, at: characterIndex, effectiveRange: nil) as? UUID
		return self.paragraphDescriptor(with: identifier!)!
	}
	
	public func paragraphDescriptors(in range: NSRange) -> [ParagraphDescriptor] {
		if self.length == 0, range.max == 0 {
			return [self.paragraphDescriptors.first!]
		}
		
		let descriptors = self.paragraphDescriptors.filter{ $0.range.contains(range.location) || $0.range.contains(range.max - 1) }
		guard !descriptors.isEmpty else {
			if range.location == self.length || range.location == 0 && self.paragraphDescriptors.count == 1 {
				return [self.paragraphDescriptors.last!]
			}
			else {
				return self.paragraphDescriptors.filter({ $0.range.location == range.location })
			}
		}
		
		return descriptors
	}
	
	public func paragraphDescriptor(with identifier: UUID) -> ParagraphDescriptor? {
		if let descriptor = self.paragraphDescriptors.filter({ $0.identifier == identifier }).first {
			return descriptor
		}
		return nil
	}
	
	public func paragraphIndex(of paragraphDescriptor: ParagraphDescriptor) -> Int {
		return self.paragraphDescriptors.index(of: paragraphDescriptor)!
	}
	
	
	/// Returns array of paragraph ranges containing a given range
	///
	/// - Parameter range: range to get the paragraphs for
	/// - Returns: array of paragraph ranges
	public func substringParagraphRanges(in range: NSRange, consistency: SubstringConsistency = .exact) -> [NSRange] {
		let selfString = self.string
		let swiftRange = Range(range, in: selfString)!
		
		// get the range of paragraphs representing given range
		let swiftParagraphsRange = selfString.paragraphRange(for: swiftRange)
		
		// substring and break into paragraphs
		let substring = String(selfString[swiftParagraphsRange])
		let paragraphs = substring.paragraphs
		
		var paragraphRanges = [NSRange]()
		let paragraphsRange = NSRange(swiftParagraphsRange, in: selfString)
		var location = paragraphsRange.location
		
		// break that range into individual paragraph ranges
		for paragraph in paragraphs {
			let length = paragraph.utf16.count
			let range = NSRange(location: location, length: length)
			paragraphRanges.append(range)
			location += length
		}
		
		// check the consistency
		guard let lastRange = paragraphRanges.last, consistency != .exact else { return paragraphRanges }
		
		if consistency == .dropLastEmptyParagraph {
			if lastRange.length == 0, lastRange.max < self.length {
				paragraphRanges = Array(paragraphRanges.dropLast())
			}
		}
		else if consistency == .includeLastEmptyParagraph {
			if lastRange.length == 0, lastRange.max < self.length {
				let nextParagraph = self.substringParagraphRanges(in: NSRange(location: lastRange.location + 1, length: 0))
				paragraphRanges[paragraphRanges.count - 1] = nextParagraph.first!
			}
		}
		
		return paragraphRanges
	}

	
	// MARK: - Helpers
	
	/// Ensures that locations of every paragraph range from given index will offset to the specified delta value
	///
	/// - Parameters:
	///   - descriptorIndex: index from which offset should be made
	///   - delta: value of the offset to make to paragraph ranges
	private func updateDescriptorLocations(from descriptorIndex: Int, delta: Int) {
		guard delta != 0 else { return }
		
		let index = descriptorIndex >= 0 ? descriptorIndex : 0
		
		var previousDescriptor = self.paragraphDescriptors[index]
		for i in descriptorIndex + 1 ..< self._paragraphDescriptors.count {
			let descriptor = self._paragraphDescriptors[i]
			if descriptor.range.location != previousDescriptor.range.max {
				self._paragraphDescriptors[i].range.location += delta
			}
			previousDescriptor = self._paragraphDescriptors[i]
		}
	}
	
	/// Creates a new paragraph descriptor with given paragraph range at the specified range
	/// and calculates delta of the upcoming changes
	///
	/// - Parameters:
	///   - index: index of the paragraph to insert a new paragraph descriptor
	///   - range: paragraph range of the upcoming paragraph descriptor
	/// - Returns: amount of changed characters
	@discardableResult
	private func addDescriptor(at index: Int, range: NSRange) -> Int {
		let delta = range.length
		
		let newDescriptor = ParagraphDescriptor(range: range)
		self._paragraphDescriptors.insert(newDescriptor, at: index)
		
		self.beginEditing()
		self.addAttribute(.identifier, value: newDescriptor.identifier, range: range)
		self.endEditing()
		
		self.paragraphDelegate?.textStorage(self, didAdd: newDescriptor)
		return delta
	}
	
	/// Removes a paragraph descriptor at the specified range and calculates delta of the upcoming changes
	///
	/// - Parameters:
	///   - index: index of the paragraph descriptor to delete
	/// - Returns: amount of changed characters
	@discardableResult
	private func deleteDescriptor(at index: Int) -> Int {
		guard self.paragraphDescriptors.count > 1 else { return 0 }
		
		let descriptor = self.paragraphDescriptors[index]
		let delta = -descriptor.range.length
		
		self.paragraphDelegate?.textStorage(self, willDelete: descriptor)
		self._paragraphDescriptors.remove(at: index)
		return delta
	}
	
	/// Creates a new paragraph descriptor with given paragraph range at the specified range
	/// and calculates delta of the upcoming changes
	///
	/// - Parameters:
	///   - index: index of the paragraph to insert a new paragraph descriptor
	///   - range: paragraph range of the upcoming paragraph descriptor
	/// - Returns: amount of changed characters
	@discardableResult
	private func editDescriptor(at index: Int, newRange: NSRange) -> Int {
		let descriptor = self.paragraphDescriptors[index]
		let delta = newRange.length - descriptor.range.length
		
		self._paragraphDescriptors[index].range = newRange
		
		self.beginEditing()
		self.addAttribute(.identifier, value: descriptor.identifier, range: newRange)
		self.endEditing()
		
		self.paragraphDelegate?.textStorage(self, didEdit: self._paragraphDescriptors[index])
		return delta
	}
}
