//
//  LoadablesAppDelegate.m
//  Loadables
//
//  Created by Vlad Alexa on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LoadablesAppDelegate.h"
#import "ToolBar.h"
#import "BSDProcessList.c"
#import <pwd.h>
#import "AuthorizationPlugins.h"
#include <CoreServices/CoreServices.h>
#import "DetailsDataSource.h"
#import "VASandboxFileAccess.h"

#ifndef NSAppKitVersionNumber14_0
#define NSAppKitVersionNumber14_0 2487
#endif

@implementation LoadablesAppDelegate

@synthesize window,searchString;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    machDefaults = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Contents/Resources/mach.plist"]];

    latestMacOsDefaults = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Contents/Resources/14.2_launchd.plist"]];
    latestMacOsOtherDefaults = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"Contents/Resources/14.2_other.plist"]];

    detailsDataSource = [[DetailsDataSource alloc] init];
    detailsOutline.dataSource = detailsDataSource;
    detailsOutline.delegate = detailsDataSource;

    toolBar = [[ToolBar alloc] init];
    toolBar.delegate = self;
    window.toolbar = toolBar.theBar;

}

- (void)dealloc
{
    [machDefaults release];
    [latestMacOsDefaults release];
    [latestMacOsOtherDefaults release];
    [toolBar dealloc];
    [detailsDataSource dealloc];
    [usrDict release];
    [sysDict release];
    [osxDict release];
    [machDict release];
    [othersDict release];
    [usrDictSearch release];
    [sysDictSearch release];
    [osxDictSearch release];
    [machDictSearch release];
    [othersDictSearch release];
    [super dealloc];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
    return YES;
}

- (void) application:(NSApplication *)app willEncodeRestorableState:(NSCoder *)coder
{
    [VASandboxFileAccess willEncodeRestorableState:coder];
}

- (void) application:(NSApplication *)app didDecodeRestorableState:(NSCoder *)coder
{
    [VASandboxFileAccess didDecodeRestorableState:coder];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification{
    if (sysDict == nil || osxDict == nil || usrDict == nil || machDict == nil) {
        usrDict = [[NSMutableDictionary alloc] init];
        sysDict = [[NSMutableDictionary alloc] init];
        osxDict = [[NSMutableDictionary alloc] init];
        machDict = [[NSMutableDictionary alloc] init];
        othersDict = [[NSMutableDictionary alloc] init];
        usrDictSearch = [[NSMutableDictionary alloc] init];
        sysDictSearch = [[NSMutableDictionary alloc] init];
        osxDictSearch = [[NSMutableDictionary alloc] init];
        machDictSearch = [[NSMutableDictionary alloc] init];
        othersDictSearch = [[NSMutableDictionary alloc] init];
        [self showMsg:@"Loading, please wait."];
        [self refresh:YES];
        [self closeMsg];
    }
}

-(NSDictionary*)dictForSelectedRowInTable:(NSTableView *)theTableView{
    NSDictionary *dict = nil;
    if (searchString.length > 0) {
        if ( theTableView == sysTable ) dict = sysDictSearch[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
        if ( theTableView == usrTable ) dict = usrDictSearch[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
        if ( theTableView == osxTable ) dict = osxDictSearch[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
        if ( theTableView == othersTable ) dict = othersDictSearch[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
    }else{
        if ( theTableView == sysTable ) dict = sysDict[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
        if ( theTableView == usrTable ) dict = usrDict[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
        if ( theTableView == osxTable ) dict = osxDict[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
        if ( theTableView == othersTable ) dict = othersDict[[NSString stringWithFormat:@"%i",theTableView.selectedRow]];
    }
    return dict;
}

#pragma mark NSTabViewDelegate

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    if (aTabView == mainTab){
        NSTableView *object = nil;
        if ([tabViewItem.identifier isEqualToString:@"system"])  object = sysTable;
        if ([tabViewItem.identifier isEqualToString:@"user"])    object = usrTable;
        if ([tabViewItem.identifier isEqualToString:@"osx"])     object = osxTable;
        if ([tabViewItem.identifier isEqualToString:@"mach"])     object = machTable;
        if ([tabViewItem.identifier isEqualToString:@"others"])     object = othersTable;
        if (object != nil) {
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"nil" object:object]]; //refresh drawer
        }else{
            //no tableview in tab
        }
    }else{
        NSRect old = drawInf.contentView.frame;
        if ([tabViewItem.label isEqualToString:@"Actions"]) {
            drawInf.contentSize = NSMakeSize(old.size.width,114);
        }
        if ([tabViewItem.label isEqualToString:@"Details"]) {
            drawInf.contentSize = NSMakeSize(old.size.width,252);
        }
        //NSView *superView = [[drawInf contentView] superview];  //NSDrawerFrame  TODO animate
    }
}

-(void)discloseInfo{
    if ([NSScreen mainScreen].frame.size.height - window.frame.size.height < 350) {
        [window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, window.frame.size.width, window.frame.size.height-350) display:YES];
    }
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"mach"]] == mainTab.selectedTabViewItem) return;
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"others"]] == mainTab.selectedTabViewItem) return;
    [drawerTab selectFirstTabViewItem:self];
    NSRect old = drawInf.contentView.frame;
    if (drawInf.state == NSDrawerOpenState && drawInf.contentSize.height > 300) {
        drawInf.contentSize = NSMakeSize(old.size.width,114);
    }else{
        [drawInf openOnEdge:NSMaxYEdge];
        drawInf.contentSize = NSMakeSize(old.size.width,330);
    }
}

- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView{

    NSMenu *ret = nil;

    NSDictionary *dict = [self dictForSelectedRowInTable:theTableView];

    NSString *title = dict[@"one"];
    NSString *path = dict[@"path"];
    NSString *executable = dict[@"executable"];
    if ((title && path) || executable) {
        ret = [[NSMenu alloc] initWithTitle:title];
    }
    if (title && path && ![path isEqualToString:@"Login Items"] && ![path isEqualToString:@"Built-In"]) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",path,title];
        [ret addItemWithTitle:fullPath action:nil keyEquivalent:@""];
        NSMenuItem *menuItem = [ret addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder:) keyEquivalent:@""];
        menuItem.target = self;
        menuItem.toolTip = fullPath;
    }
    if (title && path && executable && ![path isEqualToString:@"Login Items"] && ![path isEqualToString:@"Built-In"]) {
        // Add Separator
        [ret addItem:[NSMenuItem separatorItem]];
    }
    if (executable) {
        [ret addItemWithTitle:executable action:nil keyEquivalent:@""];
        NSMenuItem *menuItem = [ret addItemWithTitle:@"Reveal in Finder" action:@selector(revealInFinder:) keyEquivalent:@""];
        menuItem.target = self;
        menuItem.toolTip = executable;
    }

    //NSLog(@"Right clicked %ld",row);
    return [ret autorelease];
}

-(void)revealInFinder:(NSMenuItem*)sender{
    NSString *path = sender.toolTip;
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
}

#pragma mark NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSTableView *theTableView = aNotification.object;
    if (theTableView == machTable || theTableView == othersTable) {
        [drawInf close]; //table has not actions or info
        return;
    }
    if (theTableView.selectedRow < 0) {
        [drawInf close]; //no row selected has no actions or info
        return;
    }

    [toggleButton setHidden:NO];
    [toggleButton setEnabled:YES];
    //reset tooltips and titles
    toggleButton.toolTip = @"";
    stopButton.toolTip = @"Stops any running processes associated with the service";
    removeButton.toolTip = @"Entirely removes the service from the operating system";
    stopButton.title = @"Stop process";
    removeButton.title = @"Remove service";

    NSDictionary *dict = [self dictForSelectedRowInTable:theTableView];

    if (dict == nil) {
        NSLog(@"No table");
        [drawInf close];
        return; //empty selection
    }
    toggleButton.tag = theTableView.selectedRow;
    removeButton.tag = theTableView.selectedRow;
    NSString *file = [NSString stringWithFormat:@"%@/%@",dict[@"path"],dict[@"one"]];

    if ([dict[@"path"] isEqualToString:@"Login Items"]) {
        //is service
        NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:dict[@"one"]];
        if (appPath) {
            //get app plist
            NSString *infoPath = [NSString stringWithFormat:@"%@/Contents/Info.plist",appPath];
            NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:infoPath forced:NO denyNotice:@""];
            [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];
            detailsDataSource.rootItems = [NSDictionary dictionaryWithContentsOfFile:infoPath];
            [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];
            //set buttons
            [toggleButton setHidden:YES];
            [removeButton setEnabled:YES];
            NSDictionary *info = [self runningDaemonInfo:[dict[@"one"] stringByReplacingOccurrencesOfString:@".app" withString:@""]];
            if (info) {
                int uid = [info[@"uid"] intValue];
                if (uid == getuid() || [self userIsRoot:NSUserName()] == YES) {
                    stopButton.tag = [info[@"pid"] intValue];
                    [stopButton setEnabled:YES];
                }else{
                    [stopButton setEnabled:NO];
                    stopButton.toolTip = @"Not enough permissions to stop this process";
                }
            }else{
                [stopButton setEnabled:NO];
                stopButton.title = @"Not running";
            }
        }
    } else if ([dict[@"path"] isEqualToString:@"/Library/StartupItems"] || [dict[@"path"] isEqualToString:@"/System/Library/StartupItems"]) {
        //is directory
        NSString *subFile = [NSString stringWithFormat:@"%@/%@",file,dict[@"one"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:subFile]) {
            //get sub file contents
            NSError *error = nil;
            NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:subFile forced:NO denyNotice:@""];
            [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];
            detailsDataSource.rootItems = [self dictionaryFromArray:[[NSString stringWithContentsOfFile:subFile encoding:NSASCIIStringEncoding error:&error] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
            [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];
            if (error) NSLog(@"Can not read %@ (%@)",subFile,error.localizedDescription);
        }else{
            //get dir list (denied by sandbox)
            detailsDataSource.rootItems = [self dictionaryFromArray:[[NSFileManager defaultManager] subpathsAtPath:file]];
        }
        //set buttons
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:subFile]) {
            toggleButton.state = 0;
        }else{
            toggleButton.state = 1;
        }
        [stopButton setEnabled:NO];
        stopButton.title = @"N/A";
        stopButton.toolTip = @"Not available for this kind of service";
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:file]) {
            [removeButton setEnabled:YES];
            [toggleButton setEnabled:YES];
        }else{
            [removeButton setEnabled:NO];
            removeButton.toolTip = @"Not enough permissions to remove this service";
            [toggleButton setEnabled:NO];
            toggleButton.toolTip = @"Not enough permissions to modify this service";
        }
    } else {
        //is plist
        NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:file forced:NO denyNotice:@""];
        [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:file];
        [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];
        detailsDataSource.rootItems = plist;
        //set buttons
        if ([dict[@"disabled"] isEqualToString:@"YES"]) {
            toggleButton.state = 1;
        }else{
            toggleButton.state = 0;
        }
        if ([dict[@"disabled"] isEqualToString:@"Unhandled"]) {
            [toggleButton setHidden:YES];
        }
        NSString *program = [plist[@"Program"] lastPathComponent];
        if (program == nil) {
            NSString *execpath = plist[@"ProgramArguments"][0];
            program = execpath.lastPathComponent;
        }
        NSDictionary *info = [self runningDaemonInfo:program];
        if (info) {
            int uid = [info[@"uid"] intValue];
            if (uid == getuid() || [self userIsRoot:NSUserName()] == YES) {
                stopButton.tag = [info[@"pid"] intValue];
                [stopButton setEnabled:YES];
            }else{
                [stopButton setEnabled:NO];
                stopButton.toolTip = @"Not enough permissions to stop this process";
            }
        }else{
            [stopButton setEnabled:NO];
            stopButton.title = @"Not running";
        }
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:file]) {
            [removeButton setEnabled:YES];
        }else{
            [removeButton setEnabled:NO];
            removeButton.toolTip = @"Not enough permissions to remove this service";
        }
    }

    [drawInf openOnEdge:NSMaxYEdge];
    [detailsOutline reloadData];
    [detailsOutline expandItem:nil expandChildren:YES];

    //make sure actions does not disclose help if that is the selected tab
    NSRect old = drawInf.contentView.frame;
    if ([drawerTab.selectedTabViewItem.label isEqualToString:@"Actions"]) {
        drawInf.contentSize = NSMakeSize(old.size.width,114);
    };

}

#pragma mark NSTableViewDataSource

- (void)tableView:(NSTableView *)aTableView didClickTableColumn:(NSTableColumn *)theColumn{
    //NSLog(@"Sorting by %@",[theColumn identifier]);
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
    NSArray *tableSort = aTableView.sortDescriptors;
    if (tableSort) {
        if (searchString.length > 0) {
            if ( aTableView == sysTable ) [sysDictSearch setDictionary:[self sortData:sysDictSearch with:tableSort]];
            if ( aTableView == usrTable ) [usrDictSearch setDictionary:[self sortData:usrDictSearch with:tableSort]];
            if ( aTableView == osxTable ) [osxDictSearch setDictionary:[self sortData:osxDictSearch with:tableSort]];
            if ( aTableView == machTable ) [machDictSearch setDictionary:[self sortData:machDictSearch with:tableSort]];
            if ( aTableView == othersTable ) [othersDictSearch setDictionary:[self sortData:othersDictSearch with:tableSort]];
        }else{
            if ( aTableView == sysTable ) [sysDict setDictionary:[self sortData:sysDict with:tableSort]];
            if ( aTableView == usrTable ) [usrDict setDictionary:[self sortData:usrDict with:tableSort]];
            if ( aTableView == osxTable ) [osxDict setDictionary:[self sortData:osxDict with:tableSort]];
            if ( aTableView == machTable ) [machDict setDictionary:[self sortData:machDict with:tableSort]];
            if ( aTableView == othersTable ) [othersDict setDictionary:[self sortData:othersDict with:tableSort]];
        }
        [aTableView reloadData];
    }
    //NSLog(@"Sorting by %@",[tableSort description]);
    [aTableView deselectAll:self];
    [drawInf close];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView {
    if (searchString.length > 0) {
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"system"]].label = [NSString stringWithFormat:@"System Wide Services (%d)",sysDictSearch.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"user"]].label = [NSString stringWithFormat:@"Per-User  Services (%d)",usrDictSearch.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"osx"]].label = [NSString stringWithFormat:@"OSX Services (%d)",osxDictSearch.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"mach"]].label = [NSString stringWithFormat:@"Mach Services (%d)",machDictSearch.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"others"]].label = [NSString stringWithFormat:@"Others (%d)",othersDictSearch.count];
        if ( theTableView == sysTable ) return sysDictSearch.count;
        if ( theTableView == usrTable ) return usrDictSearch.count;
        if ( theTableView == osxTable ) return osxDictSearch.count;
        if ( theTableView == machTable ) return machDictSearch.count;
        if ( theTableView == othersTable ) return othersDictSearch.count;
    }else{
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"system"]].label = [NSString stringWithFormat:@"System Wide Services (%d)",sysDict.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"user"]].label = [NSString stringWithFormat:@"Per-User  Services (%d)",usrDict.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"osx"]].label = [NSString stringWithFormat:@"OSX Services (%d)",osxDict.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"mach"]].label = [NSString stringWithFormat:@"Mach Services (%d)",machDict.count];
        [mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"others"]].label = [NSString stringWithFormat:@"Others (%d)",othersDict.count];
        if ( theTableView == sysTable ) return sysDict.count;
        if ( theTableView == usrTable ) return usrDict.count;
        if ( theTableView == osxTable ) return osxDict.count;
        if ( theTableView == machTable ) return machDict.count;
        if ( theTableView == othersTable ) return othersDict.count;
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex {
    //if we have no sort descriptor for this column create one based on it's identifier (instead of setting it for each in IB,saves time and prevents errors)
    NSSortDescriptor *desc = theColumn.sortDescriptorPrototype;
    if (desc.key == nil) {
        NSSortDescriptor *sorter;
        if ([(theColumn.headerCell).title isEqualToString:@"Date"]) {
            sorter = [[NSSortDescriptor alloc] initWithKey:theColumn.identifier ascending:YES selector:@selector(compare:)];
        }else{
            sorter = [[NSSortDescriptor alloc] initWithKey:theColumn.identifier ascending:YES selector:@selector(caseInsensitiveCompare:)];
        }
        theColumn.sortDescriptorPrototype = sorter;
        [sorter release];
    }
    //also set sorting if none exists
    if (aTableView.sortDescriptors.count == 0) {
        NSTableColumn *col = [aTableView tableColumnWithIdentifier:@"path"];
        if (col == nil) col = [aTableView tableColumnWithIdentifier:@"parent"]; //if no path column exists try the parent one
        NSSortDescriptor *sorter = col.sortDescriptorPrototype;
        if (sorter) {
            aTableView.sortDescriptors = @[sorter];
        }
    }

    id ret = nil;
    NSString *row = [NSString stringWithFormat:@"%d",rowIndex];
    NSDictionary *dict = nil;
    if (searchString.length > 0) {
        if ( aTableView == sysTable ) dict = sysDictSearch[row];
        if ( aTableView == usrTable ) dict = usrDictSearch[row];
        if ( aTableView == osxTable ) dict = osxDictSearch[row];
        if ( aTableView == machTable ) dict = machDictSearch[row];
        if ( aTableView == othersTable ) dict = othersDictSearch[row];
    }else{
        if ( aTableView == sysTable ) dict = sysDict[row];
        if ( aTableView == usrTable ) dict = usrDict[row];
        if ( aTableView == osxTable ) dict = osxDict[row];
        if ( aTableView == machTable ) dict = machDict[row];
        if ( aTableView == othersTable ) dict = othersDict[row];
    }
    ret = dict[theColumn.identifier];

    if ([ret isKindOfClass:[NSString class]] && [ret length] > 0 && [theColumn.identifier isEqualToString:@"one"]) {
        //add label to name if it exists
        NSString *label = dict[@"label"];
        if (label.length > 0) ret = [ret stringByAppendingFormat:@" (%@)",label];
    }

    if ([ret isKindOfClass:[NSDate class]]) {
        ret = [ret descriptionWithCalendarFormat:@"%Y/%m/%d %H:%M:%S " timeZone:nil locale:nil];
    }

    if (aTableView == usrTable || aTableView == sysTable || aTableView == osxTable) {
        if ([ret isKindOfClass:[NSString class]] && [ret length] > 0) {

            if ([theColumn.identifier isEqualToString:@"one"]) {
                //remove .plist and .app endings
                if ([ret hasSuffix:@".app"]) ret = [ret stringByReplacingOccurrencesOfString:@".app" withString:@""];
                if ([ret hasSuffix:@".plist"]) ret = [ret stringByReplacingOccurrencesOfString:@".plist" withString:@""];

            }

            if ( [theColumn.identifier isEqualToString:@"one"] || [theColumn.identifier isEqualToString:@"path"] || [theColumn.identifier isEqualToString:@"executable"] ) {
                NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                //make gray if by default in the OS
                BOOL boo = NO;
                if (NSAppKitVersionNumber >= NSAppKitVersionNumber14_0) {
                    boo = [latestMacOsDefaults containsObject:dict[@"one"]];
                }
                if (boo == YES) {
                    attrsDictionary[NSForegroundColorAttributeName] = [NSColor secondaryLabelColor];
                }

                //make bold if a Unhandled service
                if ([dict[@"disabled"] isEqualToString:@"Unhandled"]) {
                    attrsDictionary[NSFontAttributeName] = [NSFont boldSystemFontOfSize:12.0];
                }

                if (attrsDictionary.count > 0) {
                    ret = [[[NSAttributedString alloc] initWithString:ret attributes:attrsDictionary] autorelease];
                }
            }
        }
    }

    if (aTableView == machTable) {
        if ([ret isKindOfClass:[NSString class]] && [ret length] > 0) {

            if ([theColumn.identifier isEqualToString:@"status"]) {
                if ([ret isEqualToString:@"A"])  ret = @"Active";
                if ([ret isEqualToString:@"D"])  ret = @"OnDemand";
                if ([ret isEqualToString:@"I"])  ret = @"Inactive";
            }
            if ([theColumn.identifier isEqualToString:@"one"] || [theColumn.identifier isEqualToString:@"parent"] || [theColumn.identifier isEqualToString:@"executable"]) {
                NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                //make gray if by default in the OS
                BOOL boo = [machDefaults containsObject:dict[@"one"]];
                if (boo == YES) {
                    attrsDictionary[NSForegroundColorAttributeName] = [NSColor secondaryLabelColor];
                }
                if (attrsDictionary.count > 0) {
                    ret = [[[NSAttributedString alloc] initWithString:ret attributes:attrsDictionary] autorelease];
                }
            }


        }
    }

    if (aTableView == othersTable) {
        if ([ret isKindOfClass:[NSString class]] && [ret length] > 0) {

            if ([theColumn.identifier isEqualToString:@"one"] || [theColumn.identifier isEqualToString:@"path"]) {
                NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                //make gray if by default in the OS
                BOOL boo = NO;
                if (NSAppKitVersionNumber >= NSAppKitVersionNumber14_0) {
                    boo = [latestMacOsOtherDefaults containsObject:dict[@"one"]];
                }
                if (boo == YES) {
                    attrsDictionary[NSForegroundColorAttributeName] = [NSColor secondaryLabelColor];
                }
                if (attrsDictionary.count > 0) {
                    ret = [[[NSAttributedString alloc] initWithString:ret attributes:attrsDictionary] autorelease];
                }
            }

        }
    }

    return ret;
}

-(void)addTableColumn:(NSString*)name toTable:(NSTableView*)table{
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:name];
    (column.headerCell).stringValue = name.capitalizedString;
    //[exec setMinWidth:400];
    [table addTableColumn:column];
    [column release];
}

-(NSDictionary*)sortData:(NSDictionary*)dict with:(NSArray*)tableSort{
    NSArray *sortedKeys = [dict.allKeys sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2)
                           {
        return [[[[NSNumberFormatter alloc] autorelease] numberFromString:obj1] compare:[[[NSNumberFormatter alloc] autorelease] numberFromString:obj2]];
    }];
    NSMutableArray *sortedArr = [NSMutableArray arrayWithArray:dict.allValues];
    [sortedArr sortUsingDescriptors:tableSort];
    //NSLog(@"Sorted with %@",tableSort);
    return [NSDictionary dictionaryWithObjects:sortedArr forKeys:sortedKeys];
}

-(void)reloadTables{
    if (searchString.length > 0) {
        [sysDictSearch setDictionary:[self filterDict:sysDict forString:searchString]];
        [usrDictSearch setDictionary:[self filterDict:usrDict forString:searchString]];
        [osxDictSearch setDictionary:[self filterDict:osxDict forString:searchString]];
        [machDictSearch setDictionary:[self filterDict:machDict forString:searchString]];
        [othersDictSearch setDictionary:[self filterDict:othersDict forString:searchString]];
    }
    [sysTable reloadData];
    [usrTable reloadData];
    [osxTable reloadData];
    [machTable reloadData];
    [othersTable reloadData];

    [sysTable deselectAll:self];
    [usrTable deselectAll:self];
    [osxTable deselectAll:self];
    [machTable deselectAll:self];
    [othersTable deselectAll:self];

    [drawInf close];
}

#pragma mark get data

-(void)refresh:(BOOL)all{

    //get services
    [self getServices];

    //get others
    if (all == YES)[self getOthers];

    //get running status for executable
    NSArray *runningList = [self getBSDProcessList];
    [self setRunningStatusFor:sysDict processList:runningList];
    [self setRunningStatusFor:usrDict processList:runningList];
    [self setRunningStatusFor:osxDict processList:runningList];
    [self setRunningStatusFor:machDict processList:runningList];

    //sort
    [sysDict setDictionary:[self sortData:sysDict with:sysTable.sortDescriptors]];
    [usrDict setDictionary:[self sortData:usrDict with:usrTable.sortDescriptors]];
    [osxDict setDictionary:[self sortData:osxDict with:osxTable.sortDescriptors]];
    [machDict setDictionary:[self sortData:machDict with:machTable.sortDescriptors]];
    [othersDict setDictionary:[self sortData:othersDict with:othersTable.sortDescriptors]];

    //important to do this here only because at this point the tables could display search data copied from the main data which could now have changed/be released
    [self reloadTables];

    //[self saveLocally];
}

-(void)saveLocally
{
    //save launchd plist
    NSMutableArray *save = [NSMutableArray arrayWithCapacity:1];
    for (NSString *key in sysDict) {
        NSDictionary *dict = sysDict[key];
        [save addObject:dict[@"one"]];
    }
    for (NSString *key in usrDict) {
        NSDictionary *dict = usrDict[key];
        [save addObject:dict[@"one"]];
    }
    for (NSString *key in osxDict) {
        NSDictionary *dict = osxDict[key];
        [save addObject:dict[@"one"]];
    }
    [[save sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] writeToFile:(@"~/Downloads/launchd.plist").stringByExpandingTildeInPath atomically:YES];
    [save removeAllObjects];

    //save others plist
    for (NSString *key in othersDict) {
        NSDictionary *dict = othersDict[key];
        [save addObject:dict[@"one"]];
    }
    [[save sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] writeToFile:(@"~/Downloads/other.plist").stringByExpandingTildeInPath atomically:YES];
    [save removeAllObjects];

    //save mach plist
    for (NSString *key in machDict) {
        NSDictionary *dict = machDict[key];
        [save addObject:dict[@"one"]];
    }
    [[save sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] writeToFile:(@"~/Downloads/mach.plist").stringByExpandingTildeInPath atomically:YES];
    [save removeAllObjects];
}

-(void)checkLaunchctl:(NSArray*)loadedList fileList:(NSArray*)filesList 
{
    //let's see if any of the services loaded into launchd have no such named plist
    for (NSString *name in loadedList) {
        if ([self matchStr:@".anonymous." haystack:name] || [self matchStr:@"]." haystack:name] || [self matchStr:@".mach_init." haystack:name] || [name isEqualToString:@"Label"]) {
            continue;
        }
        NSString *longName = [name stringByAppendingString:@".plist"];         
        if (![filesList containsObject:longName]) {
            NSLog(@"Mismatch, found no plist on disk to match : %@",name);
        }
    } 
}

- (void)getServices{
        
	NSString *path;
	NSArray *lsArray;	
    
	//system wide
    [sysDict removeAllObjects];
    
	path = @"/Library/StartupItems"; //SystemStarter	
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in lsArray) {
		if (item.length != 0){		
			sysDict[[NSString stringWithFormat:@"%i",sysDict.count]] = [self fileDetails:item path:path executable:nil disabledList:nil loadedList:nil];
		}
	}
    
	path = @"/System/Library/StartupItems"; //SystemStarter
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in lsArray) {
		if (item.length != 0){
			sysDict[[NSString stringWithFormat:@"%i",sysDict.count]] = [self fileDetails:item path:path executable:nil disabledList:nil loadedList:nil];
		}
	}	    
    
    //save a list of all the plists found in order to filter mach services
    NSMutableArray *filesList = [NSMutableArray arrayWithCapacity:1];    
    
    //list disabled daemons, we add those disabled by launchd
    NSArray *disabledList = [self getLaunchdDisabledList];    
    
	//list loaded osx daemons, we ignore found plists that are not known by launchd
	NSArray *loadedList = [self getLaunchdLoadedList];        
	
	path = @"/Library/LaunchDaemons";
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in lsArray) {    
		if (item.length != 0){		
            sysDict[[NSString stringWithFormat:@"%i",sysDict.count]] = [self fileDetails:item path:path executable:nil disabledList:disabledList loadedList:loadedList];            
            [filesList addObject:item];            
		}
	} 		
	
	path = @"/Library/LaunchAgents";
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in lsArray) {    
		if (item.length != 0){		
            sysDict[[NSString stringWithFormat:@"%i",sysDict.count]] = [self fileDetails:item path:path executable:nil disabledList:disabledList loadedList:loadedList];            
            [filesList addObject:item];            
		}
	}     	
	
	//user based
	[usrDict removeAllObjects];	
	
    path = [NSString stringWithFormat:@"/Users/%@/Library/LaunchAgents",NSUserName()];
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:path forced:NO denyNotice:@""];    
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];    
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];    
	for (NSString *item in lsArray) {    
		if (item.length != 0){		
            usrDict[[NSString stringWithFormat:@"%i",usrDict.count]] = [self fileDetails:item path:path executable:nil disabledList:disabledList loadedList:loadedList];            
            [filesList addObject:item];            
		}
	}    
    
	UInt32 seedValue;	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		CFArrayRef  loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for (id itemRef in (NSArray *)loginItemsArray) {		
			//get path
			CFURLRef url = NULL;
			LSSharedFileListItemResolve((LSSharedFileListItemRef)itemRef, kLSSharedFileListNoUserInteraction|kLSSharedFileListDoNotMountVolumes,&url, NULL); 
            if (url != NULL) {
                CFStringRef displayName = LSSharedFileListItemCopyDisplayName((LSSharedFileListItemRef)itemRef);
                usrDict[[NSString stringWithFormat:@"%i",usrDict.count]] = [self fileDetails:(NSString*)displayName path:@"Login Items" executable:((NSURL*)url).path disabledList:nil loadedList:nil];			
                CFRelease(displayName);
                CFRelease(url);                
            }
		}
		CFRelease(loginItemsArray);	
        CFRelease(loginItems);        
	}	
	
	//OS X Per-user agents and System wide Daemons.  
	[osxDict removeAllObjects];
    
	path = @"/System/Library/LaunchAgents";	
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in lsArray) {    
		if (item.length != 0){		
            osxDict[[NSString stringWithFormat:@"%i",osxDict.count]] = [self fileDetails:item path:path executable:nil disabledList:disabledList loadedList:loadedList];            
            [filesList addObject:item];            
		}
	}     
	
	path = @"/System/Library/LaunchDaemons";	
	lsArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *item in lsArray) {    
		if (item.length != 0){		
            osxDict[[NSString stringWithFormat:@"%i",osxDict.count]] = [self fileDetails:item path:path executable:nil disabledList:disabledList loadedList:loadedList];            
            [filesList addObject:item];            
		}
	}     
    
    //Mach services
	[machDict removeAllObjects];	
    
	lsArray = [[self execTask:@"/bin/launchctl" args:@[@"print",@"system"]] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for (NSString *line in lsArray) {
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)" options:NSRegularExpressionCaseInsensitive error:&error];
        [regex enumerateMatchesInString:line options:0 range:NSMakeRange(0, line.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            NSString *parent = [line substringWithRange:[match rangeAtIndex:1]];
            NSString *two = [line substringWithRange:[match rangeAtIndex:2]];
            NSString *three = [line substringWithRange:[match rangeAtIndex:3]];
            NSString *executable = @"";
            NSString *type = @"unknown";
            NSString *name = [line substringWithRange:[match rangeAtIndex:4]];
            if ([name hasSuffix:@".service"]) {
                type = @"service";
            }
            if ([name hasSuffix:@".xpc"]) {
                type = @"xpc";
                name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".xpc"]];
                NSURL *path = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:name];
                if (path) {
                    executable = path.path;
                }
            }
            if (name.length < 5) return;;
            machDict[[NSString stringWithFormat:@"%lu",(unsigned long)machDict.count]] = @{@"one": name,
                                 @"parent": parent,
                                 @"status": [NSString stringWithFormat:@"%@-%@", two, three],
                                 @"type": type,
                                 @"executable": executable};

        }];

        //[self checkLaunchctl:lsArray fileList:filesList];
        
    }
}    
 
-(void)getOthers{
    
    [othersDict removeAllObjects];
    
    //LoginHook
    NSDictionary *plist;
    NSArray *arr;    
    NSString *name;
    NSString *path;
    
    plist = [NSDictionary dictionaryWithContentsOfFile:(@"~/Library/Preferences/com.apple.loginwindow.plist").stringByExpandingTildeInPath];    
    name = plist[@"LoginHook"];
    if (name) {
        NSString *path = [name stringByReplacingOccurrencesOfString:name.lastPathComponent withString:@""];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",path,name].stringByStandardizingPath error:nil];        
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *owner = fileAttributes[NSFileOwnerAccountName];         
        othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"one": name.lastPathComponent,@"path": path,@"type": @"LoginHook",@"owner": owner,@"date": date};
    }
    
    plist = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/com.apple.loginwindow.plist"];    
    name = plist[@"LoginHook"];
    if (name) {
        NSString *path = [name stringByReplacingOccurrencesOfString:name.lastPathComponent withString:@""];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",path,name].stringByStandardizingPath error:nil];
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *owner = fileAttributes[NSFileOwnerAccountName];         
        othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"one": name.lastPathComponent,@"path": path,@"type": @"LoginHook",@"owner": owner,@"date": date};
    }
    
    plist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/com.apple.loginwindow.plist"];    
    name = plist[@"LoginHook"];
    if (name) {
        NSString *path = [name stringByReplacingOccurrencesOfString:name.lastPathComponent withString:@""];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",path,name].stringByStandardizingPath error:nil];
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *owner = fileAttributes[NSFileOwnerAccountName];         
        othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"one": name.lastPathComponent,@"path": path,@"type": @"LoginHook",@"owner": owner,@"date": date};
    } 
    
    //need to have root privileges, skip this if we are root to prevent duplicate with ~/Library/Preferences/com.apple.loginwindow.plist
    plist = [NSDictionary dictionaryWithContentsOfFile:@"/private/var/root/Library/Preferences/com.apple.loginwindow.plist"];    
    name = plist[@"LoginHook"];
    if (name && ![NSUserName() isEqualToString:@"root"]) {
        NSString *path = [name stringByReplacingOccurrencesOfString:name.lastPathComponent withString:@""];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@%@",path,name].stringByStandardizingPath error:nil];
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *owner = fileAttributes[NSFileOwnerAccountName];        
        othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"one": name.lastPathComponent,@"path": path,@"type": @"LoginHook",@"owner": owner,@"date": date};
    }        
    
    //built-in AuthorizationPlugins
    NSMutableArray *activeBundles = [NSMutableArray arrayWithCapacity:1];
    path = @"/System/Library/CoreServices/SecurityAgentPlugins";    
    //get loaded ones
    arr = [AuthorizationPlugins listMechanisms];
    for (NSString *name in arr) {
        if ([name hasPrefix:@"builtin:"]) {
            othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"one": name,@"path": @"Built-In",@"type": @"Authorization Plug-Ins"};
        }else{
            NSString *bundleName = [[name componentsSeparatedByString:@":"][0] stringByAppendingString:@".bundle"];
            [activeBundles addObject:bundleName];
        }
    }     
    //search the files
    for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]) {  
        if ([name isEqualToString:@".localized"] || [name isEqualToString:@".DS_Store"]) continue;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",path,name].stringByStandardizingPath error:nil];        
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *owner = fileAttributes[NSFileOwnerAccountName];        
        if ([activeBundles containsObject:name]){
            othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"label": @"active",@"one": name,@"path": path,@"type": @"Authorization Plug-Ins",@"owner": owner,@"date": date};                    
        }else{
            othersDict[[NSString stringWithFormat:@"%i",othersDict.count]] = @{@"one": name,@"path": path,@"type": @"Authorization Plug-Ins",@"owner": owner,@"date": date};                    
        }        
    }     
        
    [self addListingAt:@"/System/Library/SystemConfiguration" type:@"System Configuration" to:othersDict alsoInHome:NO];   
    [self addListingAt:@"/Library/Address Book Plug-Ins" type:@"Address Book Plugins" to:othersDict alsoInHome:YES];      
    [self addListingAt:@"/Library/Contextual Menu Items" type:@"Contextual Menu Items" to:othersDict alsoInHome:YES];  
    [self addListingAt:@"/Library/Extensions" type:@"Extensions" to:othersDict alsoInHome:YES];      
    [self addListingAt:@"/Library/InputManagers" type:@"Input Managers" to:othersDict alsoInHome:YES];
    [self addListingAt:@"/Library/Internet Plug-Ins" type:@"Internet Plugins" to:othersDict alsoInHome:YES]; 
    [self addListingAt:@"/Library/Services" type:@"Aqua Services" to:othersDict alsoInHome:YES]; 
    [self addListingAt:@"/Library/Spotlight" type:@"Spotlight Plugins" to:othersDict alsoInHome:YES];            
    [self addListingAt:@"/Library/PrivilegedHelperTools" type:@"Privileged Helper Tools" to:othersDict alsoInHome:NO];
    [self addListingAt:@"/System/Library/UserEventPlugins" type:@"User Event Plugins" to:othersDict alsoInHome:NO];
    [self addListingAt:@"/System/Library/XPCServices" type:@"XPC Services" to:othersDict alsoInHome:NO];    

}

-(void)addListingAt:(NSString*)path type:(NSString*)type to:(NSMutableDictionary*)to alsoInHome:(BOOL)home{

    for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]) {  
        if ([name isEqualToString:@".localized"] || [name isEqualToString:@".DS_Store"]) continue;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",path,name].stringByStandardizingPath error:nil];        
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *owner = fileAttributes[NSFileOwnerAccountName];        
        to[[NSString stringWithFormat:@"%i",to.count]] = @{@"one": name,@"path": path,@"type": type,@"owner": owner,@"date": date};        
    }     
    
    if (home == YES) {        
        path = [NSString stringWithFormat:@"/Users/%@%@",NSUserName(),path].stringByStandardizingPath;        
        NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:path forced:NO denyNotice:@""];    
        [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];                 
        NSArray *lsList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];           
        for (NSString *name in lsList) {        
            if ([name isEqualToString:@".localized"] || [name isEqualToString:@".DS_Store"]) continue;            
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",path,name].stringByStandardizingPath error:nil];
            NSDate *date = fileAttributes[NSFileModificationDate];
            NSString *owner = fileAttributes[NSFileOwnerAccountName];            
            to[[NSString stringWithFormat:@"%i",to.count]] = @{@"one": name,@"path": path,@"type": type,@"owner": owner,@"date": date};        
        }        
        [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];        
    }
    
}

- (NSDictionary*)fileDetails:(NSString *)name path:(NSString *)path executable:(NSString *)executable disabledList:(NSArray*)disabledList loadedList:(NSArray*)loadedList{	

    if (path == nil) path = @"";    
    if (executable == nil) executable = @"";    
    NSString *class = @"N/A";    
    NSString *type = @"N/A"; 
    NSString *label = @"";
    NSString *disabled = @"";
    if ([path isEqualToString:@"Login Items"]) {
        class = @"LoginItem";
        type = @"Application";
        return @{@"one": name,
                @"path": path,
                @"class": class,   
                @"type": type,
                @"disabled": disabled,                
                @"executable": executable, 
                @"label": label,
                @"owner": NSUserName(),                
                @"two": [self fileCDate:executable]};        
    } else if ([path isEqualToString:@"/Library/StartupItems"] || [path isEqualToString:@"/System/Library/StartupItems"]) {    
        class = @"SystemStarter";
        type = @"Script";        
        executable = [NSString stringWithFormat:@"%@/%@/%@",path,name,name];
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:executable]) {
            disabled = @"YES";             
        }    
    }else {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",path,name];
        NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:filePath forced:NO denyNotice:@""];    
        [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];                 
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:filePath];         
        [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];         
        class = @"LaunchD"; 
        executable = plist[@"Program"];
        if (executable == nil) {            
            executable = plist[@"ProgramArguments"][0];
        }        
        if (executable == nil) {            
            executable = @"";
        }
        type = @"Default";                        
        if ( [plist[@"OnDemand"] boolValue] == NO && [plist[@"RunAtLoad"] boolValue] == YES ) {
             type = @"Automatic";            
        }
        if ( [plist[@"OnDemand"] boolValue] == YES && [plist[@"RunAtLoad"] boolValue] == YES ) {
            type = @"Automatic & OnDemand";            
        }         
        if ( [plist[@"OnDemand"] boolValue] == YES ) {
             type = @"OnDemand";            
        }
        if ( [plist[@"StartOnMount"] boolValue] == YES ) {
            type = @"OnDemand";            
        }                 
        if ( plist[@"StartCalendarInterval"] != nil ) {
            type = @"Scheduled";            
        } 
        if ( plist[@"StartInterval"] != nil ) {
            type = @"Periodic";            
        }    
        if ( plist[@"Sockets"] != nil ) {
            type = @"Socket";            
        }
        if ( plist[@"WatchPaths"] != nil ) {
            type = @"FileTriggered";            
        }        
        if ( plist[@"QueueDirectories"] != nil ) {
            type = @"DirTriggered";            
        }                
        NSUInteger login = [[plist[@"LimitLoadToSessionType"] description] rangeOfString:@"LoginWindow"].location;
        if (login != NSNotFound && login != 0) {
            type = @"PreLogin";            
        }         
        //figure label
        if (plist[@"Label"]) {
            NSString *shortName = [name stringByReplacingOccurrencesOfString:@".plist" withString:@""];
            if (![shortName isEqualToString:plist[@"Label"]]) {
                label = plist[@"Label"];
                //NSLog(@"Set [%@] label for [%@] ",label,shortName);            
            }        
        }
        //figure disabled
        NSString *shortName;
        if (label.length > 0) {
            shortName = label;                                    
        }else{
            shortName = [name stringByReplacingOccurrencesOfString:@".plist" withString:@""];                                    
        }
        if ([disabledList containsObject:shortName]) { 
            disabled = @"YES";
        }else if ([loadedList containsObject:shortName]) {
            disabled = @"";
        }else{
            disabled = @"Unhandled";                
        }        
    }        
        
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",path,name].stringByExpandingTildeInPath; 
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:filePath forced:NO denyNotice:@""];    
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];      
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath.stringByStandardizingPath error:nil];   
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];    
    if(fileAttributes) {        
        return @{@"one": name,
                @"path": path,                
                @"class": class,   
                @"type": type,
                @"disabled": disabled,                 
                @"executable": executable,
                @"label": label,
                @"owner": fileAttributes[NSFileOwnerAccountName],                
                @"two": fileAttributes[NSFileModificationDate]};   
    }else{
        NSLog(@"Path (%@) is invalid.", filePath);				
    }	
    return nil;
}

- (NSDate*)fileCDate:(NSString *)file{	
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file.stringByExpandingTildeInPath.stringByStandardizingPath error:nil];    
	
    if(fileAttributes) {
        return fileAttributes[NSFileModificationDate];
    }else{
        NSLog(@"Path (%@) is invalid.", file);				
        return nil;
    }	
}


-(void)setRunningStatusFor:(NSMutableDictionary*)target processList:(NSArray*)processList {
    //make list of names
    NSMutableArray *processNames = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *dict in processList) {
        [processNames addObject:dict[@"pname"]];
    }     
    //search names
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in target) {
        NSDictionary *d = target[key];        
        NSString *name = [[d[@"executable"] lastPathComponent] stringByReplacingOccurrencesOfString:@".app" withString:@""];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:d];         
        NSUInteger index = [processNames indexOfObject:name];
        if (index != NSNotFound) {
            dict[@"runningas"] = @"unknown";    
            NSString *uid = processList[index][@"uid"];
            if (uid) {
                NSString *username = [self getNameForUID:uid.intValue];
                if (username) {
                    dict[@"runningas"] = username;
                }                
            }
        }else{
            dict[@"runningas"] = @"";            
            if ([d[@"class"] isEqualToString:@"SystemStarter"]) dict[@"runningas"] = @"N/A";            
        }
        newDict[key] = dict;
    }
    [target setDictionary:newDict];    
}

-(NSArray*)getLaunchdDisabledList{ 
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    NSString *overridesFile = [NSString stringWithFormat:@"/var/db/launchd.db/com.apple.launchd.peruser.%i/overrides.plist",getuid()];
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:overridesFile forced:NO denyNotice:@""];    
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];                 
    NSDictionary *dis = [NSDictionary dictionaryWithContentsOfFile:overridesFile];
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];    
    for (NSString *name in dis) {
        NSDictionary *p = dis[name];
        if (p && [p[@"Disabled"] boolValue] == YES) {
            [ret addObject:name];
        }        
    }
    return ret;   
}

-(NSArray*)getLaunchdLoadedList{ 
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    NSArray *arr = [[self execTask:@"/bin/launchctl" args:@[@"list"]] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in arr) {
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (components.count == 3) {
            [ret addObject:components[2]];
        }        
    }
    return ret;   
}

#pragma mark message methods

- (void)showMsg:(NSString *)msg{
	textMsg.stringValue = msg;
	[NSApp beginSheet:windowMsg modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[progMsg setUsesThreadedAnimation:YES];	
	[progMsg startAnimation:nil];
}

- (void)showNotice:(NSString *)msg{
	textMsg.stringValue = msg;
	[NSApp beginSheet:windowMsg modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    [dismissButton setHidden:NO];
}

-(IBAction)dismiss:(id)sender{
    [dismissButton setHidden:YES];    
	[NSApp endSheet:[sender window]];
	//[[sender window] close];
	[[sender window] orderOut:self];	
}

- (void)closeMsg{
	[progMsg stopAnimation:nil];
	[NSApp endSheet:windowMsg];
	[windowMsg close];
}

#pragma mark actions


-(IBAction)stopProcess:(id)sender{
    pid_t pid = (pid_t)[sender tag]; 
    [self terminatePid:pid]; 
    [self showMsg:@"Refreshing, please wait."];
    [self refresh:NO];
    [self closeMsg];      
}

-(void)terminatePid:(pid_t)pid{
    BOOL success = NO;
    //attempt to terminate with cocoa
    NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    if (app){
        success = [app terminate];
        if (success == YES) {
            //NSLog(@"Told process %i to terminate with cocoa",pid);            
            return;
        }else{
            success = [app forceTerminate];            
            if (success == YES) {
                //NSLog(@"Told process %i to terminate with cocoa (forced)",pid);
                return;
            }
        }
    }
    //cocoa attempt failed, attempt to terminate with carbon 
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	if (GetProcessForPID(pid, &psn) == noErr) {
        OSStatus result;
        AppleEvent tAppleEvent = {typeNull, 0};
        result = AEBuildAppleEvent( kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &tAppleEvent, NULL,"");
        if (result == noErr) {         
            result = AESendMessage( &tAppleEvent, NULL, kAENoReply, kAEDefaultTimeout);
            AEDisposeDesc(&tAppleEvent);
            if (result == noErr) {
                //NSLog(@"Told process %i to terminate with carbon",pid);                
                return;
            }
        }
	}  
    //carbon attempt failed, terminate with syscall to kill
    system([NSString stringWithFormat:@"kill -s TERM %i",pid].UTF8String);
    //NSLog(@"Told process %i to terminate with syscall",pid);    
}

-(IBAction)disableService:(id)sender{
    NSString *index = [NSString stringWithFormat:@"%i",[sender tag]];
    NSMutableDictionary *d = nil;
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"system"]] == mainTab.selectedTabViewItem) d = sysDict;
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"user"]] == mainTab.selectedTabViewItem) d = usrDict;
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"osx"]] == mainTab.selectedTabViewItem) d = osxDict;
    if (d) {
        NSDictionary *dict = d[index];
        if (dict) {
            NSString *class = dict[@"class"];
            NSString *name = dict[@"one"];
            if ([dict[@"label"] length] > 0) name = dict[@"label"];   
            if (class && name) {
                if ([class isEqualToString:@"LaunchD"]) {
                    [self disableServiceNamed:[name stringByReplacingOccurrencesOfString:@".plist" withString:@""]];
                    [self showMsg:@"Refreshing, please wait."];
                    [self refresh:NO];
                    [self closeMsg];                    
                }    
            }else{
                NSLog(@"Disable togle %@ failed, no name/class %@/%@",index,name,class);                
            }            
        }else{
            NSLog(@"Disable togle %@ failed, no dict",index);        
        }    
    }else{
        NSLog(@"Disable togle %@ failed, unknown table",index);
    }
}

-(void)disableServiceNamed:(NSString*)name{
    NSString *overridesFile = [NSString stringWithFormat:@"/private/var/db/launchd.db/com.apple.launchd.peruser.%i/overrides.plist",getuid()];
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:overridesFile forced:NO denyNotice:@""];    
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl];                 
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:overridesFile];   
    if ([plist[name][@"Disabled"] boolValue] == YES) {
        plist[name] = @{@"Disabled": @NO};        
    }else{
        plist[name] = @{@"Disabled": @YES};        
    }
    [plist writeToFile:overridesFile atomically:YES];
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];      
}

-(IBAction)removeService:(id)sender{
    NSString *index = [NSString stringWithFormat:@"%i",[sender tag]];
    NSMutableDictionary *d = nil;
    NSTableView *table;
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"system"]] == mainTab.selectedTabViewItem) {d = sysDict; table = sysTable;}
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"user"]] == mainTab.selectedTabViewItem) {d = usrDict; table = usrTable;}
    if ([mainTab tabViewItemAtIndex:[mainTab indexOfTabViewItemWithIdentifier:@"osx"]] == mainTab.selectedTabViewItem) {d = osxDict; table = osxTable;} 
    if (d) {
        NSDictionary *dict = d[index];
        if (dict) {
            NSString *class = dict[@"class"];
            NSString *name = dict[@"one"];
            NSString *path = dict[@"path"];            
            if (class && name && path) {
                if ([class isEqualToString:@"SystemStarter"] || [class isEqualToString:@"LaunchD"]) {
                    [self trashPath:[NSString stringWithFormat:@"%@/%@",path,name]];
                }else if  ([class isEqualToString:@"LoginItem"]){
                    [self removeLoginItem:name];
                }    
                [d removeObjectForKey:index];
                [self reorderDict:d withGapAt:index.intValue];                
                [table reloadData];
                [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"nil" object:table]]; //refresh drawer                
            }else{
                NSLog(@"Removing %@ failed, no name/class/path %@/%@/%@/",index,name,class,path);                
            }
        }else{
            NSLog(@"Removing %@ failed, no dict",index);        
        }    
    }else{
        NSLog(@"Removing %@ failed, unknown table",index);
    }
}

- (void)removeLoginItem:(NSString*)appName
{
    NSString *prefs = [NSString stringWithFormat:@"/Users/%@/Library/Preferences/loginwindow.plist",NSUserName()];
    NSURL *secScopedUrl = [VASandboxFileAccess sandboxFileHandle:prefs forced:NO denyNotice:@""];
    [VASandboxFileAccess startAccessingSecurityScopedResource:secScopedUrl]; 
    if (![[NSFileManager defaultManager] isWritableFileAtPath:secScopedUrl.path]){
        NSLog(@"Access denied to %@ %@",prefs,secScopedUrl.query);
        [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];       
        return;
    }               
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:prefs];   
    NSMutableArray *apps = dict[@"AutoLaunchedApplicationDictionary"];
    NSString *path = [NSURL fileURLWithPath:[NSBundle mainBundle].bundlePath].path; 
    NSDictionary *found = nil;
    for (NSDictionary *app in apps){
        if ([[app[@"Path"] lastPathComponent] isEqualToString:appName]) {
            found = app;
        }
    }    
    if (found) {
        [apps removeObject:found];
        dict[@"AutoLaunchedApplicationDictionary"] = apps;
        [dict writeToFile:prefs atomically:YES];
        NSLog(@"Removed %@ from login items",path);            
    }
    [VASandboxFileAccess stopAccessingSecurityScopedResource:secScopedUrl];    
}

- (void)trashPath:(NSString*)path{
    /*
    [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:path]] completionHandler:^(NSDictionary *trashPaths, NSError *error) {
                                 if (error != nil) {
                                     NSLog(@"ERROR trashing %@: %@",path,error);
                                 } else {
                                     NSLog(@"Trashed %@ (%@)",path,trashPaths);
                                 }
                             }];    
    return;     
    */
    
    NSArray *files = @[path.lastPathComponent];
    NSString *sourceDir = [path stringByReplacingOccurrencesOfString:path.lastPathComponent withString:@""]; 
    NSInteger sync;    
    
    BOOL success = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:sourceDir.stringByStandardizingPath destination:nil files:files tag:&sync];
    if (success) {
        NSLog(@"Trashed %@ (%@)",path,sourceDir);
        NSSound *snd;
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
            snd = [[NSSound alloc] initWithContentsOfFile:@"/System/Library/Components/CoreAudio.component/Contents/Resources/SystemSounds/dock/drag to trash.aif" byReference:NO];
        } else {
            snd = [[NSSound alloc] initWithContentsOfFile:@"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/drag to trash.aif" byReference:NO];
        }         
        [snd play];
        [snd release];
    }else{
        NSLog(@"Failed to trash %@ (%@)",path,sourceDir);
        NSSound *snd = [NSSound soundNamed:@"Ping"];
        [snd play]; 
    }
}

#pragma mark process info

- (NSDictionary*)runningDaemonInfo:(NSString*)appName { 
    NSArray *list = [self getBSDProcessList];
    for (NSDictionary *dict in list) {
        NSString *name = dict[@"pname"];
        if ([name isEqualToString:appName]) {
            //NSLog(@"%@ is running",appName);            
            return dict;         
        }
    }  
    return nil;
}

- (NSDictionary *)infoForPID:(pid_t)pid {
    NSDictionary *ret = nil;
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	if (GetProcessForPID(pid, &psn) == noErr) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,kProcessDictionaryIncludeAllInformationMask); 
        ret = [NSDictionary dictionaryWithDictionary:(NSDictionary *)cfDict];
        CFRelease(cfDict);
	}
	return ret;
}

- (NSArray*)getCarbonProcessList{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
	ProcessSerialNumber psn = { kNoProcess, kNoProcess };
	while (GetNextProcess(&psn) == noErr) {
		CFDictionaryRef cfDict = ProcessInformationCopyDictionary(&psn,  kProcessDictionaryIncludeAllInformationMask);
		if (cfDict) {
			NSDictionary *dict = (NSDictionary *)cfDict;
            [ret addObject:@{@"pname": [NSString stringWithFormat:@"%@",dict[(id)kCFBundleNameKey]],
                            @"pid": [NSString stringWithFormat:@"%@",dict[@"pid"]],
                            @"uid": [NSString stringWithFormat:@"%d",(uid_t)getuid()]}]; 
			CFRelease(cfDict);			
		}
	}
	return ret;
}

- (NSArray*)getBSDProcessList{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    kinfo_proc *mylist;
    size_t mycount = 0;
    mylist = (kinfo_proc *)malloc(sizeof(kinfo_proc));
    GetBSDProcessList(&mylist, &mycount);
    //printf("There are %d processes.\n", (int)mycount);
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        //NSLog(@"%s is running with pid %d",proc->kp_proc.p_comm,proc->kp_proc.p_pid);      
        NSString *fullName = [self infoForPID:proc->kp_proc.p_pid][(id)kCFBundleNameKey];
        if (fullName == nil) fullName = [NSString stringWithFormat:@"%s",proc->kp_proc.p_comm];
        [ret addObject:@{@"pname": fullName,
                        @"pid": [NSString stringWithFormat:@"%d",proc->kp_proc.p_pid],
                        @"uid": [NSString stringWithFormat:@"%d",proc->kp_eproc.e_ucred.cr_uid]}];                                            
    }
    free(mylist);  
    return ret;
}

- (NSString*)getNameForUID:(int)uid{
    if (uid < 0) return nil;    
    struct passwd *pw = getpwuid((uid_t)uid);
    if (pw) {
        char *username = pw->pw_name;
        if (username) {
            return [NSString stringWithFormat:@"%s",username];
        }        
    }
    return nil;
}

-(BOOL)userIsRoot:(NSString*)username{
    if ([username isEqualToString:@"root"]) return YES;
    //TODO if uid is member of wheel group 
    return NO;
}


#pragma mark tools

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args{
	NSTask *task = [[[NSTask alloc] init] autorelease];
	task.launchPath = launch;
	task.arguments = args;
	
    //get the stdout    
	NSPipe *pipe = [NSPipe pipe];
	task.standardOutput = pipe;
    
    //get the stderr
	NSPipe *errPipe = [NSPipe pipe];    
    task.standardError = errPipe;
    
    //keeps your subsequent nslogs from being redirected
    task.standardInput = [NSPipe pipe];      
	
	NSFileHandle *file = pipe.fileHandleForReading;
	
    //set a timer to terminate the task if not done in a timely manner
    NSTimer *timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:task selector:@selector(terminate) userInfo:nil repeats:NO];    
    
	[task launch];	
	[task waitUntilExit];
    [timeoutTimer invalidate];    
	
	if (!task.running) {	
		if (task.terminationStatus == 0){
			//NSLog(@"Task %@ succeeded.",launch);
			NSData *data = [file readDataToEndOfFile];	
			NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			return [string autorelease];		
		}else{
			//NSLog(@"Task %@ failed.",launch);	
		}		
	}else {
        NSLog(@"Task %@ failed to complete.",launch);
	}
	
	return nil;		
}

- (BOOL)matchStr:(NSString *)needle haystack:(NSString *)haystack
{
    if (needle == nil || haystack == nil) return NO;
	
	NSRange subRange = [haystack rangeOfString:needle options:(NSCaseInsensitiveSearch)];
	
	if (subRange.location == NSNotFound){
		//NSLog(@"No match for %@ (index %i, length %i)",needle ,subRange.location, subRange.length);
		return NO;
	}else{
		//NSLog(@"Matched %@ at (index %i, length %i)",needle ,subRange.location, subRange.length);		
		return YES;		
	}
	
}

-(NSDictionary*)filterDict:(NSDictionary*)source forString:(NSString*)query{    
    query = query.lowercaseString;    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in source) {
        NSDictionary *dict = source[key];
        NSString *name = [dict[@"one"] lowercaseString];
        NSString *executable = [dict[@"executable"] lowercaseString];
        NSString *parent = [dict[@"parent"] lowercaseString];
        NSString *path = [dict[@"path"] lowercaseString];        
        if (query.length > 1) {
            //full search if 2 chars or more
            if ([self matchStr:query haystack:name] || [self matchStr:query haystack:executable] || [self matchStr:query haystack:parent] || [self matchStr:query haystack:path]) {
                ret[[NSString stringWithFormat:@"%i",ret.count]] = dict;
            }
        }else if (query.length == 1) {
            //prefix search if only one char
            if ( [name hasPrefix:query] || [executable hasPrefix:query] || [parent hasPrefix:query] || [path hasPrefix:query] ) {
                ret[[NSString stringWithFormat:@"%i",ret.count]] = dict;
            }            
        }            
    }    
    return ret;
}

-(void)reorderDict:(NSMutableDictionary*)dict withGapAt:(NSInteger)index{
    NSMutableDictionary *new = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in dict) {
        NSDictionary *d = dict[key];
        if (key.intValue < index) {
            new[key] = d;
        }else{
            new[[NSString stringWithFormat:@"%i",key.intValue-1]] = d;            
        }
    }
    [dict setDictionary:new];
}

-(NSArray*)mergeArraysFilteringDuplicates:(NSArray*)one with:(NSArray*)two{
    NSMutableArray *ret = [NSMutableArray arrayWithArray:one];       
    for (NSString *foo in two) {
        if (![ret containsObject:foo]) {
            [ret addObject:foo];
        }
    }    
    return ret;    
}

-(NSDictionary*)dictionaryFromArray:(NSArray*)arr{
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:1];
    int count = 0;
    for (id foo in arr) {
        [keys addObject:[NSString stringWithFormat:@"%i",count]];
        count++;
    }
    return [NSDictionary dictionaryWithObjects:arr forKeys:keys];
}

@end


@implementation NSColor (StringOverrides)

+(NSArray *)controlAlternatingRowBackgroundColors{
	return @[[NSColor windowBackgroundColor],[NSColor windowBackgroundColor]];
}

@end
