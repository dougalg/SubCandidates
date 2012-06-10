//
//  SubCandidatesInputController.m
//  SubCandidates
//
//  Created by Dougal Graham on 12-06-08.
//  Copyright (c) 2012 CrackerSoft. All rights reserved.
//

#import "SubCandidatesInputController.h"
#import "SubCandidatesAppDelegate.h"
#import "ConversionEngine.h"

extern IMKCandidates* candidates;
extern IMKCandidates* subCandidates;

@implementation SubCandidatesInputController

-(id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)inputClient {
    // Set the string for the subcandidates dropdown
    // I do it during initialization, assuming just one subCandidates instance
    // but, of course, it could be dynamic as well
    _subCandidateString = @"SubCandidates HERE";
    
    return [super initWithServer:server delegate:delegate client:inputClient];
}

/*
 Implement one of the three ways to receive input from the client. 
 Here are the three approaches:
 
 1.  Support keybinding.  
 In this approach the system takes each keydown and trys to map the keydown to an action method that the input method has implemented.  If an action is found the system calls didCommandBySelector:client:.  If no action method is found inputText:client: is called.  An input method choosing this approach should implement
 -(BOOL)inputText:(NSString*)string client:(id)sender;
 -(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender;
 
 2. Receive all key events without the keybinding, but do "unpack" the relevant text data.
 Key events are broken down into the Unicodes, the key code that generated them, and modifier flags.  This data is then sent to the input method's inputText:key:modifiers:client: method.  For this approach implement:
 -(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender;
 
 3. Receive events directly from the Text Services Manager as NSEvent objects.  For this approach implement:
 -(BOOL)handleEvent:(NSEvent*)event client:(id)sender;
 */

/*!
 @method     
 @abstract   Receive incoming text.
 @discussion This method receives key board input from the client application.  The method receives the key input as an NSString. The string will have been created from the keydown event by the InputMethodKit.
 */
-(BOOL)inputText:(NSString*)string client:(id)sender
{
    // Return YES to indicate the the key input was received and dealt with.  Key processing will not continue in that case.
    // In other words the system will not deliver a key down event to the application.
    // Returning NO means the original key down will be passed on to the client.
    BOOL                    inputHandled = NO;
    // The parser is an NSScanner
    NSScanner*              scanner = [NSScanner scannerWithString:string];
    // Check the input.  If it is possibly part of a decimal number remember that.
    NSString*               resultString;
    // Let's imagine that we only want to accept alphanumeric entries
    BOOL                    isInLetterSet = [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ1234567890"] intoString:&resultString];
    // Holds the line number
    int                     theLineNumber = 0;

    // We're going to check if the user input a line number for quick insertion
    // if it's not an int, it will return a 0
    if (isInLetterSet)
        theLineNumber = [resultString intValue];

    // If it's an int (>0, <10) we might need to close the candidate windows
    // and commit the composition
    if ( isInLetterSet && theLineNumber > 0 && theLineNumber < 10 && _didShowCandidates == YES ) {
        IMKCandidates* currentCandidates;
        if ([subCandidates isVisible] == YES)
            currentCandidates = subCandidates;
        else
            currentCandidates = candidates;
        
        // We move to that line and then commit the composition
        // or display subcandidates as necessary
        if (currentCandidates) {
            NSInteger finalLine = theLineNumber - 1;
            NSInteger theIdentifier = [currentCandidates candidateIdentifierAtLineNumber:finalLine];
            [currentCandidates selectCandidateWithIdentifier:theIdentifier];
            // Make sure it isn't the option that holds subCandidates
            // if it is, we need to display them, not close and commit
            NSString* currentString = [[currentCandidates selectedCandidateString] string];
            if ([currentString isEqualToString:_subCandidateString]) {
                [candidates hideChild];
                [self candidateSelectionChanged:[candidates selectedCandidateString]];
            } else {
                [self setComposedBuffer:currentString];
                [self commitComposition:sender];
                
                _didShowCandidates = NO;
                _subCandidatesExist = NO;
                
                [candidates hideChild];
                [candidates hide];
            }
        }
        inputHandled = YES;
    } else if ( isInLetterSet ) {
        // If the input text is a letter.  Add it to the original buffer, and return that we handled it.
        [self originalBufferAppend:string client:sender];
        
        // If the candidates window is open, close it
        if (candidates && [candidates isVisible] == YES) {
            [candidates hideChild];
            [candidates hide];
        }
        _didShowCandidates = NO;
        _didConvert = NO;
        inputHandled = YES;
    }
    else {
        // If the input isn't part of a possible word see if we need to convert the previously input text.
        inputHandled = [self convert:string client:sender];
    }
    return inputHandled;
}

/*!
 @method     
 @abstract   Called when a user action was taken that ends an input session.   Typically triggered by the user selecting a new input method or keyboard layout.
 @discussion When this method is called your controller should send the current input buffer to the client via a call to insertText:replacementRange:.  Additionally, this is the time to clean up if that is necessary.
 */

-(void)commitComposition:(id)sender 
{
    NSString*		text = [self composedBuffer];

    if ( text == nil || [text length] == 0 )
        text = [self originalBuffer];
    
    // Dismiss subCandidates if visible
    if (subCandidates && [subCandidates isVisible] == YES)
        [candidates hideChild];
    
    [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    
    [self setComposedBuffer:@""];
    [self setOriginalBuffer:@""];
    _insertionIndex = 0;
    _didConvert = NO;
    _didShowCandidates = NO;
    _subCandidatesExist = NO;
    _subCandidateData = nil;
}

// Return the composed buffer.  If it is NIL create it.  
-(NSMutableString*)composedBuffer;
{
    if ( _composedBuffer == nil ) {
        _composedBuffer = [[NSMutableString alloc] init];
    }
    return _composedBuffer;
}

// Change the composed buffer.
-(void)setComposedBuffer:(NSString*)string
{
    NSMutableString*		buffer = [self composedBuffer];
    [buffer setString:string];
}


// Get the original buffer.
-(NSMutableString*)originalBuffer
{
    if ( _originalBuffer == nil ) {
        _originalBuffer = [[NSMutableString alloc] init];
    }
    return _originalBuffer;
}

// Add newly input text to the original buffer.
-(void)originalBufferAppend:(NSString*)string client:(id)sender
{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer appendString: string];
    _insertionIndex++;
    [sender setMarkedText:buffer selectionRange:NSMakeRange(0, [buffer length]) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

// Change the original buffer.
-(void)setOriginalBuffer:(NSString*)string
{
    NSMutableString*		buffer = [self originalBuffer];
    [buffer setString:string];
}

#pragma mark - Selectors

// This method is called to see if your input method handles an NSResponder action.
-(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender
{
    if ([self respondsToSelector:aSelector]) {
        // The NSResponder methods like insertNewline: or deleteBackward: are
        // methods that return void. didCommandBySelector method requires
        // that you return YES if the command is handled and NO if you do not. 
        // This is necessary so that unhandled commands can be passed on to the
        // client application. For that reason we need to test in the case where
        // we might not handle the command.
        
        //
        //The test here is simple.  Test to see if any text has been added to the original buffer.
        NSString*		bufferedText = [self originalBuffer];
        if ( bufferedText && [bufferedText length] > 0 ) {
            if (aSelector == @selector(insertNewline:) ||
                aSelector == @selector(deleteBackward:) ||
                aSelector == @selector(cancelOperation:) ||
                aSelector == @selector(moveUp:) ||
                aSelector == @selector(moveDown:) ||
                aSelector == @selector(moveRight:) ||
                aSelector == @selector(moveLeft:)) {
                [self performSelector:aSelector withObject:sender];
                return YES; 
            }
        }
    }
    return NO;
}

// When the left arrow key is pressed
- (void)moveLeft:(id)sender
{   
    // If subCandidates is visible, hide it
    if (subCandidates && [subCandidates isVisible] == YES) {
        [candidates hideChild];
    }
}

// When the right arrow key is pressed
- (void)moveRight:(id)sender
{
    // If subcandidates exist and are visible, and we're on the right line
    // move to the first of the subCandidates subList
    if (subCandidates && [[[candidates selectedCandidateString] string] isEqualToString:_subCandidateString]) {
        // Show the window if we need to
        if ([subCandidates isVisible] == NO) {
            [candidates showChild];
        }
        // Select the first choice
        [subCandidates selectCandidate:[subCandidates candidateIdentifierAtLineNumber:0]];
    }
}

// When the down arrow key is pressed
- (void)moveDown:(id)sender
{
    [self selectNextCandidate];
}

// When the up arrow key is pressed
- (void)moveUp:(id)sender
{
    [self selectPreviousCandidate];
}

// When a new line is input we commit the composition.
// Do nothing if the current candidate is hosting a subMenu
- (void)insertNewline:(id)sender
{
    // If we have subCandidates and this is the correct line, then we should show the subCandidates window
    if (subCandidates && [subCandidates isVisible] == NO && candidates && [candidates isVisible] == YES && [[[candidates selectedCandidateString] string] isEqualToString:_subCandidateString]) {
        [candidates showChild];
    } else {
        // Otherwise hide what is showing and commit
        if (candidates && [candidates isVisible] == YES) {
            [self setComposedBuffer:[[candidates selectedCandidateString] string]];
            [candidates hide];
        }
        if (subCandidates && [subCandidates isVisible] == YES) {
            [self setComposedBuffer:[[subCandidates selectedCandidateString] string]];
            [subCandidates hide];
        }
        [self commitComposition:_currentClient];
    }
}

// If backspace is entered remove the preceding character and update the marked text TO THE ROMAN INPUT
// hide the subCandidates in visible
- (void)deleteBackward:(id)sender
{
    NSMutableString*		originalText = [self originalBuffer];
    //NSArray*				convertedStrings;
    //NSString*				convertedString;
    
    if (candidates && [candidates isVisible] == YES) {
        [candidates hide];
    }
    if (subCandidates && [subCandidates isVisible] == YES) {
        [candidates hideChild];
    }
    if ( _insertionIndex > 0 && _insertionIndex <= [originalText length] ) {
        --_insertionIndex;
        [originalText deleteCharactersInRange:NSMakeRange(_insertionIndex,1)];
        
        /* Once preferences are implemented we can add a mode to allow this style of typing
         * where the deleting shows the Thai rather than the romanized version
         
         convertedStrings = [[[NSApp delegate] conversionEngine] convert:originalText withLimit:-1];
         if ([convertedStrings count] > 0) {
         convertedString = [convertedStrings objectAtIndex:0];
         } else {
         convertedString = originalText;
         }*/
        
        [self setComposedBuffer:originalText];
        [sender setMarkedText:originalText selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
    }
}

// When using the escape key
// If the subCandidate window is open, close it
// If not, if the candidate window is open, close it
// If not, convert the text to roman input
// If the text is already roman, commit the composition? Or delete it all?
- (void)cancelOperation:(id)sender {
    if (subCandidates && [subCandidates isVisible] == YES) {
        [self setComposedBuffer:[[subCandidates selectedCandidateString] string]];
        [candidates hideChild];
    } else if ((candidates && [candidates isVisible] == YES)) {
        [self setComposedBuffer:[[candidates selectedCandidateString] string]];
        [candidates hide];
    } else if ([[self originalBuffer] isEqualToString:[self composedBuffer]]) {
        [self commitComposition:sender];
    } else {
        _didConvert = NO;
        [self setComposedBuffer:[self originalBuffer]];
        [sender setMarkedText:[self originalBuffer] selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
    }
}

#pragma mark - Converting

// This method converts buffered text based on the trigger string.  If we did convert the text previously insert the converted text with
// the trigger string appended to the converted text.  
// If we have not done a previous conversion check to see if the input string is a space.  If it is convert the text mark it in the client, and remember that we did do a conversion.
// If the input text is not a string.  Commit the composition, and then insert the input string.
- (BOOL)convert:(NSString*)trigger client:(id)sender
{
    NSString*				originalText = [self originalBuffer];
    NSString*				convertedString = [self composedBuffer];
    NSArray*				convertedStrings;
    BOOL					handled = NO;
    
    if ( _didConvert && convertedString && [convertedString length] > 0  ) {
        
        if ( candidates ) {
            // If candidates aren't visible, set them up and show them
            // This should be the 2nd press of space
            if ( ([trigger isEqual: @" "] && _didShowCandidates == NO) || _didShowCandidates == YES ) {
                _currentClient = sender;
                
                [candidates show:kIMKLocateCandidatesBelowHint];
                
                // Attach the subCandidates if necessary
                if (_subCandidatesExist == YES) {
                    [subCandidates setCandidateData:_subCandidateData];
                    NSUInteger theIndentifier = [candidates candidateStringIdentifier:_subCandidateString];
                    [candidates attachChild:subCandidates toCandidate:(NSInteger)theIndentifier type:kIMKSubList];
                }
                
                if (_didShowCandidates == YES) {
                    //If the candidates are already shown, then select the next candidate
                    [self selectNextCandidate];
                } else {
                    // Otherwise select the first one
                    _didShowCandidates = YES;
                    
                    // Select the first candidate
                    NSInteger identifier = [candidates candidateIdentifierAtLineNumber:0];
                    [candidates selectCandidateWithIdentifier:identifier];
                }
            }
            handled = YES;
        }
        else {
            
            NSString*		completeString = [convertedString stringByAppendingString:trigger];
            
            [sender insertText:completeString replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
            
            [self setComposedBuffer:@""];
            [self setOriginalBuffer:@""];
            _insertionIndex = 0;
            _didConvert = NO;
            handled = YES;
        }
        
    }
    else if ( originalText && [originalText length] > 0 ) {
        convertedStrings = [[[NSApp delegate] conversionEngine] convert:originalText];
        
        if ([convertedStrings count] > 0) {
            convertedString = [convertedStrings objectAtIndex:0];
        } else {
            convertedString = originalText;
        }
        [self setComposedBuffer:convertedString];
        
        // First press of space converts the text
        if ( [trigger isEqual: @" "] ) {
            [sender setMarkedText:convertedString selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
            _didConvert = YES;
            _didShowCandidates = NO;
        }
        else {
            [self commitComposition:sender];
            [sender insertText:trigger replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        }
        handled = YES;
    }
    return handled;
}

#pragma mark - Selection

// Moves the candidate selection to the next one down
- (void)selectNextCandidate {
    [self selectCandidateByRowOffset:1];
}

// Moves the Candidate selection to the previous one up 
- (void)selectPreviousCandidate {
    [self selectCandidateByRowOffset:-1];
}

// Move to a candidate row specified by a certain offset
// If that candidate is not located, move to first row
- (void)selectCandidateByRowOffset:(NSUInteger) offset {
    IMKCandidates*        currentCandidates;
    if (subCandidates && [subCandidates isVisible] == YES) {
        currentCandidates = subCandidates;
    } else if (candidates && [candidates isVisible] == YES) {
        currentCandidates = candidates;
        [candidates hideChild];
    }
    if (currentCandidates) {
        NSInteger candidateIdentifier = [currentCandidates selectedCandidate];
        NSInteger lineNumber = [currentCandidates lineNumberForCandidateWithIdentifier:candidateIdentifier];
        NSInteger nextIdentifier = [currentCandidates candidateIdentifierAtLineNumber:lineNumber+offset];
        if (nextIdentifier == NSNotFound) {
            nextIdentifier = [currentCandidates candidateIdentifierAtLineNumber:0];
        }
        [currentCandidates selectCandidateWithIdentifier:nextIdentifier];
    }
    
    // We have to call self candidateSelectionChanged for subCandidates to update the string
    if (currentCandidates == subCandidates)
        [self candidateSelectionChanged:[subCandidates selectedCandidateString]];
}

- (NSArray*)candidates:(id)sender
{
    NSArray*                mainCandidates = [NSArray array];
    ConversionEngine*		engine = [[NSApp delegate] conversionEngine];
    NSString*				originalString = [self originalBuffer];
    
    _subCandidateData = [NSArray array];
    _subCandidatesExist = NO;
    
    // Build the array of candidates by converting the original text
    mainCandidates = [engine convert:originalString];
    
    // and we'll just generate the data the same way
    _subCandidateData = [engine convert:@"Some subCandidates"];
    
    // We'll add the trigger to the submenu in final or 9th position (index 8), whichever is lower
    if ([mainCandidates count] > 0) {
        NSMutableArray* theCandidates = [NSMutableArray arrayWithArray:mainCandidates];
        if ([_subCandidateData count] > 0) {
            _subCandidatesExist = YES;
            
            NSUInteger theIndex = NSIntegerMax;
            // Here we decide where to put the subCandidates string
            if ([mainCandidates count] > 8) {
                theIndex = 8;
                [theCandidates insertObject:_subCandidateString atIndex:theIndex];
            } else {
                theIndex = [theCandidates count];
                [theCandidates addObject:_subCandidateString];
            }
        }
        [self setComposedBuffer:[theCandidates objectAtIndex:0]];
        return theCandidates;
    } else {
        return [NSArray array];
    }
}

- (void)candidateSelectionChanged:(NSAttributedString*)candidateString
{
    // If there are subcandidates, check if we need to show them
    // otherwise, swap the text
    if (_subCandidatesExist == YES && [subCandidates isVisible] == NO) {
        NSInteger candidateIdentifier = [candidates selectedCandidate];
        NSInteger subCandidateStringIdentifier = [candidates candidateStringIdentifier:_subCandidateString];
        // If this is the candidate with subs, then show them and swap for the first one,
        // otherwise swap the text
        if (candidateIdentifier == subCandidateStringIdentifier) {
            // Set the data
            [subCandidates setCandidateData:_subCandidateData];
            
            // Set the location
            NSRect currentFrame = [candidates candidateFrame];
            NSPoint windowInsertionPoint = NSMakePoint(NSMaxX(currentFrame), NSMaxY(currentFrame));
            [subCandidates setCandidateFrameTopLeft:windowInsertionPoint];
            
            // Attach and show
            [candidates attachChild:subCandidates toCandidate:(NSInteger)candidateIdentifier type:kIMKSubList];
            [candidates showChild];
            // Select the first choice
            [subCandidates selectCandidate:[subCandidates candidateIdentifierAtLineNumber:0]];
            
            candidateString = [subCandidates selectedCandidateString];
        }
    }
    [_currentClient setMarkedText:[candidateString string] selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
}

/*!
 @method     
 @abstract   Called when a new candidate has been finally selected.
 @discussion The candidate parameter is the users final choice from the candidate window. The candidate window will have been closed before this method is called.
 */
- (void)candidateSelected:(NSAttributedString*)candidateString
{
    [self setComposedBuffer:[candidateString string]];
    [self commitComposition:_currentClient];
}

-(void)dealloc {
    [_subCandidateData release];
    [super dealloc];
}

@end
