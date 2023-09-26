//
//  VATableView.m
//  Loadables
//
//  Created by Vlad Alexa on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VATableView.h"

@implementation VATableView

@dynamic delegate;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:mousePoint];
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    //NSLog(@"Right clicked %ld",row);
    return [self.delegate menuForClickedRow:row inTable:self];
    return [super menuForEvent:theEvent];
}

@end
