//
//  DescriptedTextStorageTests.swift
//  CoreTests
//
//  Created by Vitaliy Vashchenko on 12/27/17.
//  Copyright © 2017 Cine Studio. All rights reserved.
//

import XCTest
import Extensions
@testable import CineKit

class Delegate: DescriptedTextStorageDelegate {
	var paragraphs: [ParagraphDescriptor] = []

	func textStorage(_ textStorage: DescriptedTextStorage, didAdd paragraphDescriptor: ParagraphDescriptor) {
		let index = textStorage.paragraphIndex(of: paragraphDescriptor)
		paragraphs.insert(paragraphDescriptor, at: index)
	}
	
	func textStorage(_ textStorage: DescriptedTextStorage, willDelete paragraphDescriptor: ParagraphDescriptor) {
		let index = textStorage.paragraphIndex(of: paragraphDescriptor)
		paragraphs.remove(at: index)
	}
	
	func textStorage(_ textStorage: DescriptedTextStorage, didEdit paragraphDescriptor: ParagraphDescriptor) {
		let index = textStorage.paragraphIndex(of: paragraphDescriptor)
		paragraphs[index].range = paragraphDescriptor.range
	}
	
	func textStorage(_ textStorage: DescriptedTextStorage, shouldSetStyleFor paragraphDescriptor: ParagraphDescriptor) -> TextStyle? {
		return nil
	}
}


class CoreTests: XCTestCase {
	
	let textStorage = DescriptedTextStorage()
	let delegate = Delegate()

    override func setUp() {
        super.setUp()
		
		// Put setup code here. This method is called before the invocation of each test method in the class.
		textStorage.paragraphDelegate = delegate
		delegate.paragraphs.append(textStorage.paragraphDescriptors.first!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDescriptedTextStorage_Initialization() {
		let textStorage = DescriptedTextStorage()
		XCTAssertTrue(textStorage.paragraphDescriptors.isEmpty == false,
					  "DescriptedTextStorage should have one paragraph descriptor at init")
	}
	
	func testDescriptedTextStorage_DelegateInitialNotification() {
		XCTAssertTrue(delegate.paragraphs.count == 1,
					  "DescriptedTextStorage delegate should be notified of the first descriptor when assigned")
	}
	
	
	// MARK: - Insertion Tests
	
	func testDescriptedTextStorage_InsertFirstParagraphs() {
		let string = "First paragraph\nSecond paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: string.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: string.paragraphs[1].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
					  textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			XCTAssertTrue(value as! UUID == textStorage.paragraphDescriptors[index].identifier &&
						  range == textStorage.paragraphDescriptors[index].range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_InsertEmptyAtBeginning() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "\n"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "\nFirst paragraph\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_InsertNonemptyAtBeginning() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "\naddition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "\nadditionFirst paragraph\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_InsertEmptyInMiddle() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "\n"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 3, length: 5), with: editString)
		textStorage.endEditing()
		
		let endString = "Fir\nragraph\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_InsertNonemptyInMiddle() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "\naddition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 3, length: 5), with: editString)
		textStorage.endEditing()
		
		let endString = "Fir\nadditionragraph\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
					  textStorage.paragraphDescriptors[1].range == secondRange &&
					  textStorage.paragraphDescriptors[2].range == thirdRange &&
					  textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_InsertEmptyBetweenParagraphs() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "\n"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 16, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\n\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_InsertNonemptyBetweenParagraphs() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "addition\n"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 16, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\naddition\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_InsertEmptyAtEnd() {
		let string = "First paragraph\nSecond paragraph\nThird"
		let editString = "\n"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: string.utf16.count, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\nSecond paragraph\nThird\n"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_InsertNonemptyAtEnd() {
		let string = "First paragraph\nSecond paragraph\nThird"
		let editString = "\naddition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: string.utf16.count, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\nSecond paragraph\nThird\naddition"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	
	
	// MARK: - Editing Tests
	
	func testDescriptedTextStorage_EditFirstParagraph() {
		let string = "First paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()

		let endString = "First paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 1,
					  "DescriptedTextStorage should now have 1 paragraph descriptor")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_EditParagraphAtBeginning() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		let editString = "addition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "additionFirst paragraph\nSecond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_EditParagraphInMiddle() {
		let string = "First paragraph\nSecond paragraph"
		let editString = "addition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 3, length: 5), with: editString)
		textStorage.endEditing()
		
		let endString = "Firadditionragraph\nSecond paragraph"

		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_EditParagraphAtEnd() {
		let string = "First paragraph\nSecond paragraph"
		let editString = "addition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: string.utf16.count, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\nSecond paragraphaddition"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_EditEmptyParagraphAtEnd() {
		let string = "First paragraph\nSecond paragraph\n"
		let editString = "a"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: string.utf16.count, length: 0), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\nSecond paragraph\na"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	
	// MARK: - Deletion Tests
	
	func testDescriptedTextStorage_DeleteParagraphInMiddle() {
		let string = "First paragraph\nSecond paragraph\nThird paragraph\nFourth paragraph"

		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 15, length: 5), with: "")
		textStorage.endEditing()
		
		let endString = "First paragraphnd paragraph\nThird paragraph\nFourth paragraph"

		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteParagraphAtEnd() {
		let string = "First paragraph\nSecond paragraph\nThird paragraph"

		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()

		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 32, length: 5), with: "")
		textStorage.endEditing()

		let endString = "First paragraph\nSecond paragraphd paragraph"

		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")

		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")

		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)

		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}

			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteWholeParagraphAtBeginning() {
		let string = "First paragraph\nSecond paragraph\nThird paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: string.paragraphsFilled[0].utf16.count), with: "")
		textStorage.endEditing()
		
		let endString = "Second paragraph\nThird paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_DeleteWholeParagraphInMiddle() {
		let string = "First paragraph\nSecond paragraph\nThird paragraph\nFourth paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 16, length: string.paragraphsFilled[1].utf16.count), with: "")
		textStorage.endEditing()
		
		let endString = "First paragraph\nThird paragraph\nFourth paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteWholeParagraphAtEnd() {
		let string = "First paragraph\nSecond paragraph\nThird paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 32, length: string.paragraphsFilled[2].utf16.count + 1), with: "")
		textStorage.endEditing()
		
		let endString = "First paragraph\nSecond paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		print(endString.paragraphs[1])
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	
	// MARK: - Mixed Tests
	
	func testDescriptedTextStorage_DeleteWholeParagraphAtBeginningAndEditNextOne() {
		let string = "First paragraph\nSecond💋 paragraph\nThird paragraph\nFourth paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: string.paragraphsFilled[0].utf16.count + 3), with: "")
		textStorage.endEditing()
		
		let endString = "ond💋 paragraph\nThird paragraph\nFourth paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	func testDescriptedTextStorage_DeleteWholeTwoParagraphsAtBeginningAndEditNextOne() {
		let string = "First paragraph\nSeco💋nd paragraph\nThird paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 35 + 3), with: "")
		textStorage.endEditing()
		
		let endString = "rd paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 1,
					  "DescriptedTextStorage should now have 1 paragraph descriptor")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteWholeTwoParagraphsAtBeginningEditingTheNextOneAndInsertNewParagraph() {
		let string = "First paragraph\nSecond pa💋ragraph\nThird paragraph\nFourth paragraph"

		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()

		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 35 + 3), with: "new paragraph\n")
		textStorage.endEditing()

		let endString = "new paragraph\nrd paragraph\nFourth paragraph"

		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")

		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")

		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)

		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}

			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteTwoParagraphsInMiddleEditingTheNextOneAndInsertNewParagraph() {
		let string = "First paragraph\nSecond parag💋raph\nThird paragraph\nFourth paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 15, length: 18 + 3), with: "new paragraph\n")
		textStorage.endEditing()
		
		let endString = "First paragraphnew paragraph\nhird paragraph\nFourth paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteOneParagraphInMiddleEditingTheNextOneAndInsertNewParagraph() {
		let string = "First paragraph\nSecond parag💋raph\nThird paragraph\nFourth paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 34, length: 3), with: "new paragraph\n")
		textStorage.endEditing()
		
		let endString = "First paragraph\nSecond parag💋raphnew paragraph\nird paragraph\nFourth paragraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_IncrementallyAddAndEditParagraphAtEndAndPeriodicallyInsertNewParagraphInMiddle() {
		var lastRange = NSRange(value: textStorage.length)
		var ranges = [lastRange]
		var endString = ""
		var additionallyAdded = 0
		
		for i in 0 ..< 50 {
			// every 10 iterations, remove and add the range
			if i % 10 == 0, i > 0 {
				let index = i - 5
				let range = textStorage.paragraphDescriptor(atParagraphIndex: index).range
				let addRange = NSRange(location: range.location, length: 0)
				textStorage.beginEditing()
				textStorage.replaceCharacters(in: addRange, with: "\n")
				textStorage.endEditing()
				endString.insert("\n", at: Range(addRange, in: endString)!.upperBound)
				
				let string = String(describing: i)
				let editRange = NSRange(location: addRange.max, length: 0)
				textStorage.beginEditing()
				textStorage.replaceCharacters(in: editRange, with: string)
				textStorage.endEditing()
				endString.insert(contentsOf: string, at: Range(editRange, in: endString)!.upperBound)
				let changedRange = NSRange(location: addRange.location, length: 1 + string.utf16.count)
				ranges.insert(changedRange, at: index)
				
				for idx in index + 1 ..< ranges.count {
					ranges[idx].location += 1 + string.utf16.count
				}
				lastRange = NSRange(location: textStorage.length, length: 0)
				additionallyAdded += 1
			}

			let string = String(describing: i)
			textStorage.beginEditing()
			textStorage.replaceCharacters(in: lastRange, with: string)
			textStorage.endEditing()
			endString += string
			lastRange.length += string.utf16.count
			
			textStorage.beginEditing()
			textStorage.replaceCharacters(in: NSRange(location: lastRange.max, length: 0), with: "\n")
			textStorage.endEditing()
			lastRange.length += 1
			
			endString += "\n"
			ranges[i + additionallyAdded] = lastRange
			
			lastRange = NSRange(location: textStorage.length, length: 0)
			ranges.append(lastRange)
		}
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == ranges.count,
					  "DescriptedTextStorage should now have \(ranges.count) paragraph descriptors")
		
		let storageRanges = textStorage.paragraphDescriptors.compactMap{ $0.range }
		
		XCTAssertTrue(storageRanges == ranges,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_IncrementallyAddAndEditParagraphAtEndAndThemDeleteBunchOfThem() {
		var lastRange = NSRange(value: textStorage.length)
		
		for i in 0 ..< 50 {
			let string = String(describing: i)
			textStorage.beginEditing()
			textStorage.replaceCharacters(in: lastRange, with: string)
			textStorage.endEditing()
			lastRange.length += string.utf16.count
			
			textStorage.beginEditing()
			textStorage.replaceCharacters(in: NSRange(location: lastRange.max, length: 0), with: "\n")
			textStorage.endEditing()
			lastRange.length += 1
			
			lastRange = NSRange(location: textStorage.length, length: 0)
		}
		
		let range = NSRange(location: 5, length: textStorage.length - 10)
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: range, with: "")
		textStorage.endEditing()

		let endStrig = "0\n1\n28\n49\n"
		let endParagraphs = endStrig.paragraphs
		var paragraphs: [NSRange] = []
		var theRange = NSRange(value: 0)
		for paragraph in endParagraphs {
			theRange = NSRange(location: theRange.max, length: paragraph.utf16.count)
			paragraphs.append(theRange)
		}

		XCTAssertTrue(textStorage.paragraphDescriptors.count == paragraphs.count,
					  "DescriptedTextStorage should now have \(paragraphs.count) paragraph descriptors")
		
		let storageRanges = textStorage.paragraphDescriptors.compactMap{ $0.range }
		
		XCTAssertTrue(storageRanges == paragraphs,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_ReplaceAllParagraphsWithTwoNewParagraphs() {
		let string = "First paragraph\nSecond 💋paragraph\nThird paragraph"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: string.utf16.count), with: "new paragraph\nanotherParagraph")
		textStorage.endEditing()
		
		let endString = "new paragraph\nanotherParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_InsertBlankParagraphInMiddleAndInsertAnotherOne() {
		let string = "First paragraph\nSecond paragraph\nThird paragraph\nFourthOne"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 16, length: 0), with: "\n")
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 34, length: 0), with: "\n")
		textStorage.endEditing()
		
		let endString = "First paragraph\n\nSecond paragraph\n\nThird paragraph\nFourthOne"
		let endParagraphs = endString.paragraphs
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 6,
					  "DescriptedTextStorage should now have 6 paragraph descriptors")
		
		var paragraphs: [NSRange] = []
		var lastRange = NSRange(value: 0)
		for paragraph in endParagraphs {
			lastRange = NSRange(location: lastRange.max, length: paragraph.utf16.count)
			paragraphs.append(lastRange)
		}

		let storageRanges = textStorage.paragraphDescriptors.compactMap({ $0.range })
		XCTAssertTrue(storageRanges == paragraphs,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_DeleteParagraphInMiddleAndEditingTheNextOne() {
		let string = "First paragraph\nSecond paragraph💋\nThirdParagraph"
		let editString = "\naddition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 15, length: 1), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\nadditionSecond paragraph💋\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(value as! UUID == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_InsertBetweenParagraphsBlankParagraphEditingTheNextOne() {
		let string = "First paragraph\nSe🤙cond paragraph\nThirdParagraph"
		let editString = "\naddition"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 16, length: 1), with: editString)
		textStorage.endEditing()
		
		let endString = "First paragraph\n\nadditione🤙cond paragraph\nThirdParagraph"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 4,
					  "DescriptedTextStorage should now have 4 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)
		let fourthRange = NSRange(location: NSMaxRange(thirdRange), length: endString.paragraphs[3].utf16.count)

		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange &&
			textStorage.paragraphDescriptors[3].range == fourthRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let identifier = value as! UUID
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(identifier == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_IncrementalEditingAndInsertingParagraph() {
		let string = "1"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 1, length: 0), with: "\n")
		textStorage.endEditing()
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 2, length: 0), with: "2")
		textStorage.endEditing()
		let endString = "1\n2"

		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let identifier = value as! UUID
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(identifier == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_IncrementalEditingAndMakeFirstParagraphEmpty() {
		let string = "1\n2"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 1), with: "")
		textStorage.endEditing()
		let endString = "\n2"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let identifier = value as! UUID
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(identifier == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_IncrementalEditingAndMakeMiddleParagraphEmpty() {
		let string = "1\n2\n3"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 2, length: 1), with: "")
		textStorage.endEditing()
		let endString = "1\n\n3"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 3,
					  "DescriptedTextStorage should now have 3 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		let thirdRange = NSRange(location: NSMaxRange(secondRange), length: endString.paragraphs[2].utf16.count)

		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange &&
			textStorage.paragraphDescriptors[2].range == thirdRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let identifier = value as! UUID
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(identifier == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}
	
	func testDescriptedTextStorage_IncrementalEditingAndMakeLastParagraphEmpty() {
		let string = "1\n2"
		
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 2, length: 1), with: "")
		textStorage.endEditing()
		let endString = "1\n"
		
		XCTAssertTrue(textStorage.paragraphDescriptors.count == 2,
					  "DescriptedTextStorage should now have 2 paragraph descriptors")
		
		let firstRange = NSRange(location: 0, length: endString.paragraphs[0].utf16.count)
		let secondRange = NSRange(location: NSMaxRange(firstRange), length: endString.paragraphs[1].utf16.count)
		
		XCTAssertEqual(textStorage.paragraphDescriptors, delegate.paragraphs)
		XCTAssertTrue(textStorage.paragraphDescriptors[0].range == firstRange &&
			textStorage.paragraphDescriptors[1].range == secondRange,
					  "DescriptedTextStorage descriptor ranges should be correct")
		
		// check identifiers in the storage attributes
		var index = 0
		textStorage.enumerateAttribute(.identifier, in: NSRange(location: 0, length: textStorage.length), options: []) {
			(value, range, stop) in
			if index >= textStorage.paragraphDescriptors.count {
				XCTAssertTrue(false, "DescriptedTextStorage descriptor count should match count of identifiers in the storage attributes")
				return
			}
			
			let identifier = value as! UUID
			let descriptor = textStorage.paragraphDescriptors[index]
			XCTAssertTrue(identifier == descriptor.identifier && range == descriptor.range,
						  "DescriptedTextStorage descriptor should match storage attributes")
			index += 1
		}
	}

	
	// MARK: - Custom Attributes
	
	func testDescriptedTextStorage_SetCustomTextAttributes() {
		let string = "First paragraph\nSecond paragraph\nThirdParagraph"
		textStorage.beginEditing()
		textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: string)
		textStorage.endEditing()
		
		let changeRange = NSMakeRange(15, 5)
		textStorage.beginEditing()
		textStorage.setAttributes([.foregroundColor: Color.blue], range: changeRange)
		textStorage.endEditing()
		
		var count = 0
		textStorage.enumerateAttribute(.identifier, in: changeRange, options: []) { (value, range, stop) in
			XCTAssertNotNil(value as? UUID)
			
			let identifier = value as! UUID
			let syncedDescriptor = textStorage.paragraphDescriptors[count]
			XCTAssertTrue(identifier == syncedDescriptor.identifier, "Paragraph identifier at index \(count) doesn't match")
			
			var theRange = NSRange()
			textStorage.attribute(.identifier, at: range.location, longestEffectiveRange: &theRange, in: syncedDescriptor.range)
			XCTAssertTrue(theRange == syncedDescriptor.range, "Identifier range at index \(count) doesn't match its paragraph range")
			count += 1
		}
		XCTAssertTrue(count == 2, "DescriptedTextStorage should have 2 identifiers in current range")
	}
}
