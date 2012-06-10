
//
//  main.m
//  SubCandidates
//
//  Created by Dougal Graham on 12-06-08.
//  Copyright (c) 2012 CrackerSoft. Free to use and modify
//

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

// Each input method needs a unique connection name. 
// Note that periods and spaces are not allowed in the connection name.
// Change this for your application, it should match the value for InputMethodConnectionName
// in the plist 
const NSString* kConnectionName = @"SubCandidates_Connection";

//let this be a global so our application controller delegate can access it easily
IMKServer*          server;
IMKCandidates*		candidates = nil;
IMKCandidates*		subCandidates = nil;
    
int main(int argc, char *argv[])
{   
    NSString*       identifier;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Find the bundle identifier and then initialize the input method server
    identifier = [[NSBundle mainBundle] bundleIdentifier];
    // This sets up the server to use the IMKInputController class named in the plist
    // under InputMethodServerControllerClass
    // If you'd like a delegate you can add it with the key: InputMethodServerDelegateClass
    server = [[IMKServer alloc] initWithName:(NSString*)kConnectionName bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    
    // Load the bundle explicitly because in this case the input method is a background only application 
    [NSBundle loadNibNamed:@"MainMenu" owner:[NSApplication sharedApplication]];
    
    // Create the candidate windows
    candidates = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];
    // If you try to init both with a server it gets confused...
    subCandidates = [[IMKCandidates alloc] initWithServer:nil panelType:kIMKSingleColumnScrollingCandidatePanel];
    
    // Set the window to send key events to the input controller first
    // Here I copied the default attributes and add the new item to them
    // but they appear to be null by default
    NSDictionary* attributes = [candidates attributes];
    NSMutableDictionary* newAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    [newAttributes setValue:@"YES" forKey:@"IMKCandidatesSendServerKeyEventFirst"];
    [candidates setAttributes:newAttributes];
    
    // Finally run everything
    [[NSApplication sharedApplication] run];
    
    [server release];
    [candidates release];
    [subCandidates release];
    
    [pool release];
    
    return 0;
}
