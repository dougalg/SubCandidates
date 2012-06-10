//
//  SubCandidatesInputController.h
//  SubCandidates
//
//  Created by Dougal Graham on 12-06-08.
//  Copyright (c) 2012 CrackerSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <InputMethodKit/InputMethodKit.h>

@interface SubCandidatesInputController : IMKInputController {
    //_composedBuffer contains text that the input method has converted
    NSMutableString*                _composedBuffer;
    //_original buffer contains the text has it was received from user input.
    NSMutableString*                _originalBuffer;
    //used to mark where text is being inserted in the _composedBuffer
    NSInteger                       _insertionIndex;
    //This flag indicates that the original text was converted once in response to a trigger (space key)
    //the next time the trigger is received the composition will be committed.
    BOOL                            _didConvert;
    BOOL                            _didShowCandidates;
    //the current active client.
    id                              _currentClient;

    // For storing subCandidate data
    NSArray*                        _subCandidateData;
    // Line number at which to attach the candidate
    NSString*                       _subCandidateString;
    // Are there subcandidates?
    BOOL                            _subCandidatesExist;
}

//These are simple methods for managing our composition and original buffers
//They are all simple wrappers around basic NSString methods.
-(NSMutableString*)composedBuffer;
-(void)setComposedBuffer:(NSString*)string;

-(NSMutableString*)originalBuffer;
-(void)originalBufferAppend:(NSString*)string client:(id)sender;
-(void)setOriginalBuffer:(NSString*)string;

- (BOOL)convert:(NSString*)trigger client:(id)sender;

- (void)selectNextCandidate;
- (void)selectPreviousCandidate;
- (void)selectCandidateByRowOffset:(NSUInteger) offset;
@end
