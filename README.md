# NSTextStorage-with-paragraph-tracking

DescriptedTextStorage is a subclass of NSTextStorage class. It works with whole paragraphs of text and notifies its	paragraph delegate if user changes any paragraphs. Delegate receives touched paragraph descriptors.

This behavior is important when any paragraph represents a specific object in your model. So, every single change to the text storage will be	reflected	in the appropriate object of your model.

As a result, you now get an opportunity to track changes by paragraph and reflect those changes to your model and make it easy to persist with, let's say, Core Data.

### Usage:
Just include DescriptedTextStorage.swift, ParagraphDescriptor.swift and CustromAttributes.swift in your project. Optionally you can add DescriptedTextStorageTests.swift into the Unit Test target of your project to make sure everything works fine.

### Basic Algorhythm Description:
The ParagraphDescriptor struct basically holds the identifier of the paragraph and its range in the text storage.

The DescriptedTextStorage object calculates paragraph ranges in the edited range every time when replaceCharacterInRage method gets called. Diring the attribute fixing it sets as an attribute the identifer of the paragraph descriptor corresponding with the changed paragraph range.

If user sets some attribute in the text storage, the DescriptedTextStorage object will make sure that those new attribute will have the correct paragraph idenifier before actually setting the attrubutes.

## All written in Swift 4.0.

###### Performance is really good.
###### Last time I checked, I got topmost 16% of CPU utilization in System Monitor even when I keep bumping my keyboard non-stop (Apple Pages will take at least 30-35% of CPU when you type fast, so I consider my job done well).
###### Performance might drop when you select and delete a super huge block of text (like 30-40 pages of text at once), but since that is a rare situation, I decided to forget about it. My focus was on the bulletproof algorhythm that is super efficient in common scenarios.
