//
//  ToolBar.m
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ToolBar.h"
#import "LoadablesAppDelegate.h"

#define MAIN_OBSERVER_NAME_STRING @"VADiskFailureEvent"

@implementation ToolBar

@synthesize theBar,delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
	
        //init array with icon params and start adding
        NSMutableDictionary *params =[NSMutableDictionary dictionaryWithCapacity:1];

        params[@"1"] = @{@"Name": @"Refresh",
                           @"Tip": @"Refresh the list",
                           @"Icon": @"refresh",
                           @"Act": @"tbclickRefresh:"};
        params[@"2"] = @{@"Name": @"Info",
                           @"Tip": @"Some things depend on user authorizations",
                           @"Icon": @"info",
                           @"Act": @"tbclickInfo:"};
        params[@"3"] = @{@"Name": @"Search",
                           @"Tip": @"Search the tables"};

        //create icons from params
        items = [[NSMutableDictionary alloc] init];
        id key;
        NSEnumerator *loop = [params keyEnumerator];
        while ((key = [loop nextObject])) {
            NSDictionary *dict = params[key];
            items[dict[@"Name"]] = [self configureToolbarItem: dict];
        }
        
        //add generic items
        items[NSToolbarSpaceItemIdentifier] = [[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSpaceItemIdentifier] autorelease];
        items[NSToolbarFlexibleSpaceItemIdentifier] = [[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier] autorelease];
        items[NSToolbarFlexibleSpaceItemIdentifier] = [[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier] autorelease];
        items[NSToolbarSeparatorItemIdentifier] = [[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSeparatorItemIdentifier] autorelease];             
        
        //add a toolbar
        theBar = [[NSToolbar alloc] initWithIdentifier:@"tbar"];
        theBar.delegate = self;
        [theBar setAllowsUserCustomization:YES];
        [theBar setAutosavesConfiguration:YES];
        
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    delegate.searchString = [aNotification.object stringValue];
    [delegate reloadTables];
}    

#pragma mark toolbar datasource

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:optionsDict[@"Name"]];
	item.paletteLabel = optionsDict[@"Name"];
	item.label = optionsDict[@"Name"];
	item.toolTip = optionsDict[@"Tip"];
    
    if ([optionsDict[@"Name"] isEqualToString:@"Search"]) {
        NSSearchField *srcfld = [[[NSSearchField alloc] init] autorelease];
        srcfld.delegate = self;       
        item.view = srcfld;
    }else{
        if([optionsDict[@"Icon"] isEqualToString:@"info"] && [self userIsRoot:NSUserName()] == YES) {
            item.image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))];           
        }else{
            item.image = [NSImage imageNamed:optionsDict[@"Icon"]];            
        }    
        item.target = self;
        item.action = NSSelectorFromString(optionsDict[@"Act"]);        
    }
	return [item autorelease];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)thetoolbar itemForItemIdentifier:(NSString *)itemIdentifier  willBeInsertedIntoToolbar:(BOOL)flag 
{
    return items[itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)thetoolbar
{
    return items.allKeys;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)thetoolbar
{  
    return @[@"Info",
            NSToolbarSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,            
            NSToolbarFlexibleSpaceItemIdentifier,            
            @"Refresh",            
            NSToolbarFlexibleSpaceItemIdentifier,                        
            @"Search"];
}


#pragma mark toolbar actions

- (void)tbclickRefresh:(NSToolbarItem*)item{
    [delegate showMsg:@"Refresh requested, please wait."];
    [delegate refresh:YES];	
    [delegate closeMsg];    
}     

- (void)tbclickInfo:(NSToolbarItem*)item{
    if([self userIsRoot:NSUserName()] == YES) {
        [delegate showNotice:@"Running as root, be sure you know what you are doing or else you could damage the operating system."];        
    }else{
        [delegate discloseInfo];
    }       
}

-(BOOL)userIsRoot:(NSString*)username{
    if ([username isEqualToString:@"root"]) return YES;
    //TODO if uid is member of wheel group 
    return NO;
}

@end
