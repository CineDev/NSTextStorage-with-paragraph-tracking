# NSTextStorage-with-paragraph-tracking

DescriptedTextStorage is a subclass of NSTextStorage class. It works with whole paragraphs of text and notifies its	paragraph delegate if user changes any paragraphs. Delegate receives touched paragraph descriptors.

This behavior is important when any paragraph represents a specific object in your model. So, every single change to the text storage will be	reflected	in the appropriate object of your model.

As a result, you now get an opportunity to track changes paragraph-by-paragraph and reflect those changes in your model. That will make it easy not only to build a custom business logic with your model, but also to convert that model into a persistant state using, let's say, Core Data.

##### Important: do not enable lazily attribute fixing (fixesAttributesLazily property) since it will get the whole algorhythm broken.

### Usage:
Just include DescriptedTextStorage.swift, ParagraphDescriptor.swift, CustromAttributes.swift and String+Extensions.swift in your project. Optionally you can add DescriptedTextStorageTests.swift into the Unit Test target of your project to make sure everything works fine.

#### Basic code to make it work:

    // setup the system
    let textStorage = DescriptedTextStorage()
    textStorage.paragraphDelegate = yourDelegateObject
    
    // make sure the deletage is syncronized with the blank text storage state (a blank text storage still has one empty paragraph)
    textStorage.paragraphDelegate?.textStorage(textStorage, didAdd: textStorage.paragraphDescriptor(atParagraphIndex: 0))
    
##### Implementing the conformance to DescriptedTextStorageDelegate protocol, use the 'identifier' property of a ParagraphDescriptor object to sync your model with paragraphs of the text storage.

That's it!

The rest is up to you and depends how you would implement the DescriptedTextStorageDelegate protocol which will update your model synchronously with changes in text storage paragraphs.
    
But all the heavy job is done: the text storage will automatically track all the paragraph changes and immediately notify its paragraphDelegate.

### Basic Algorhythm Description:
The ParagraphDescriptor struct basically holds the identifier of the paragraph and its range in the text storage.

The DescriptedTextStorage object calculates paragraph ranges in the edited range every time when replaceCharacterInRage method gets called. Diring the attribute fixing it sets as an attribute the identifer of the paragraph descriptor corresponding with the changed paragraph range.

If user sets some attribute in the text storage without changing the text, the DescriptedTextStorage object will make sure that those new attributes have the correct paragraph idenifier before actually applying the attrubutes.

## Written in Swift 4.0

###### Performance is really good. Last time I checked, I got topmost 16% of CPU utilization in System Monitor even when I keep bumping my keyboard non-stop (Apple Pages will take at least 30-35% of CPU when you type fast, so I consider my job done well). Performance might drop when you select and delete a super huge block of text (like 30-40 pages of text at once), but since that is a rare situation, I decided to forget about it. My focus was on the bulletproof algorhythm that is super efficient in common scenarios.
