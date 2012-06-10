//
//  ConversionEngine.m
//  SubCandidates
//
//  Created by Dougal Graham on 12-06-08.
//  Copyright (c) 2012 CrackerSoft. Free to use and modify.
//

#import "ConversionEngine.h"

@implementation ConversionEngine

-(void)awakeFromNib
{
    // Do any set up you need to do..
}

// This assumes that for each string entered there are multiple possible return values,
// if not, just change it to a string
-(NSArray*)convert:(NSString*)string {
    NSMutableArray* theResults = [[NSMutableArray alloc] init];
    
    // Let's just output a random set of strings between 6 and 11 (5+6)
    int numStrings = (arc4random() % 5) + 6;
    
    NSString* theString;
    for (int n = 1; n <= numStrings; n++) {
        theString = [NSString stringWithFormat:@"Result %i", n];
        [theResults addObject: theString];
    }
    [theResults addObject:string];
    return [theResults autorelease];
}

-(void)dealloc {
    [super dealloc];
}

@end