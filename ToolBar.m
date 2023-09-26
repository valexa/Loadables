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

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
	
        //init array with icon params and start adding
        NSMutableDictionary *params =[NSMutableDictionary dictionaryWithCapacity:1];
        
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Sharing", @"Name",
                           @"Sharing Preferences", @"Tip",
                           @"sharing", @"Icon",
                           @"tbclickSharing:", @"Act", 
                           nil] forKey:@"1"];
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Login", @"Name",
                           @"Login Preferences", @"Tip",
                           @"account", @"Icon",
                           @"tbclickLogin:", @"Act", 
                           nil] forKey:@"2"];
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Refresh", @"Name",
                           @"Refresh the list", @"Tip",
                           @"refresh", @"Icon",
                           @"tbclickRefresh:", @"Act", 
                           nil] forKey:@"3"];      	        
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Info", @"Name",
                           @"Some things depend on user authorizations", @"Tip",
                           @"info", @"Icon",
                           @"tbclickInfo:", @"Act",
                           nil] forKey:@"4"];   
        [params setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           @"Search", @"Name",
                           @"Search the table", @"Tip",
                           nil] forKey:@"5"];           
        
        //create icons from params
        items = [[NSMutableDictionary alloc] init];
        id key;
        NSEnumerator *loop = [params keyEnumerator];
        while ((key = [loop nextObject])) {
            NSDictionary *dict = [params objectForKey:key];
            [items setObject:[self configureToolbarItem: dict] forKey:[dict objectForKey: @"Name"]];
        }
        
        //add generic items
        [items setObject:[[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSpaceItemIdentifier] autorelease] forKey:NSToolbarSpaceItemIdentifier];
        [items setObject:[[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier] autorelease] forKey:NSToolbarFlexibleSpaceItemIdentifier];
        [items setObject:[[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier] autorelease] forKey:NSToolbarFlexibleSpaceItemIdentifier];
        [items setObject:[[[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarSeparatorItemIdentifier] autorelease] forKey:NSToolbarSeparatorItemIdentifier];             
        
        //add a toolbar
        theBar = [[NSToolbar alloc] initWithIdentifier:@"tbar"];
        [theBar setDelegate:self];
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
    [delegate setSearchString:[[aNotification object] stringValue]];
    [delegate reloadTables];
}    

#pragma mark toolbar datasource

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:[optionsDict objectForKey:@"Name"]];
	[item setPaletteLabel: [optionsDict objectForKey: @"Name"]];
	[item setLabel: [optionsDict objectForKey: @"Name"]];
	[item setToolTip: [optionsDict objectForKey: @"Tip"]];
    
    if ([[optionsDict objectForKey: @"Name"] isEqualToString:@"Search"]) {
        NSSearchField *srcfld = [[[NSSearchField alloc] init] autorelease];
        [srcfld setDelegate:self];       
        [item setView:srcfld];        
        [item setMinSize:NSMakeSize(60,22)];
        [item setMaxSize:NSMakeSize(140,22)];        
    }else{
        if([[optionsDict objectForKey: @"Icon"] isEqualToString:@"info"] && [self userIsRoot:NSUserName()] == YES) {
            [item setImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(UTGetOSTypeFromString((CFStringRef)@"caut"))]];           
        }else{
            [item setImage:[NSImage imageNamed:[optionsDict objectForKey: @"Icon"]]];            
        }    
        [item setTarget:self];
        [item setAction:NSSelectorFromString([optionsDict objectForKey: @"Act"])];        
    }
	return [item autorelease];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)thetoolbar itemForItemIdentifier:(NSString *)itemIdentifier  willBeInsertedIntoToolbar:(BOOL)flag 
{
    return [items objectForKey:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)thetoolbar
{
    return [items allKeys];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)thetoolbar
{  
    return [NSArray arrayWithObjects:             
            @"Info",
            NSToolbarSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,            
            NSToolbarFlexibleSpaceItemIdentifier,            
            @"Refresh",            
            NSToolbarFlexibleSpaceItemIdentifier, 
            //@"Login",            
            //@"Sharing",                        
            @"Search",
            //NSToolbarSeparatorItemIdentifier,            
            nil];
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

- (void)tbclickSharing:(NSToolbarItem*)item{
	[self runAscript:@"\
	 tell application \"System Preferences\" \n\
	 activate \n\
	 set the current pane to pane id \"com.apple.preferences.sharing\" \n\
	 end tell"];
}

- (void)tbclickLogin:(NSToolbarItem*)item{
	[self runAscript:@"\
	 tell application \"System Preferences\" \n\
	 activate \n\
	 set the current pane to pane id \"com.apple.preferences.users\" \n\
	 get the name of every anchor of pane id \"com.apple.preferences.users\" \n\
	 reveal anchor \"startupItemsPref\" of pane id \"com.apple.preferences.users\" \n\
	 end tell"];	      
}


- (void)runAscript:(NSString*)script
{
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
	
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:script];
	
    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
    [scriptObject release];
	
    if (returnDescriptor != NULL)
    {
        // successful execution
        if (kAENullEvent != [returnDescriptor descriptorType])
        {
            // script returned an AppleScript result
            if (cAEList == [returnDescriptor descriptorType])
            {
				// result is a list of other descriptors
            }
            else
            {
                // coerce the result to the appropriate ObjC type
            }
        }
    }
    else
    {
		CFShow(errorDict);
    }		
}

-(BOOL)userIsRoot:(NSString*)username{
    if ([username isEqualToString:@"root"]) return YES;
    //TODO if uid is member of wheel group 
    return NO;
}

@end
