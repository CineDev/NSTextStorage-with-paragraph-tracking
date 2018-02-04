# NSTextStorage-with-paragraph-tracking

DescriptedTextStorage is a subclass of NSTextStorage class. It works with whole paragraphs of text and notifies its	paragraph delegate if user changes any paragraphs. Delegate receives touched paragraph descriptors.

This behavior is important when any paragraph represents a specific object in your model. So, every single change to the text storage will be	reflected	in the appropriate object of your model.

As a result, you now get an opportunity to track changes by paragraph and reflect those changes to your model and make it easy to persist with, let's say, Core Data.

Just include DescriptedTextStorage.swift and ParagraphDescriptor.swift in your project. Optionally you can add DescriptedTextStorageTests.swift in the Unit Test target of your project to make sure everything works fine.

## All written in Swift 4.0.
