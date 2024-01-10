//
//  LoadablesAppDelegate.h
//  Loadables
//
//  Created by Vlad Alexa on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ToolBar;
@class DetailsDataSource;

@interface LoadablesAppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate,NSTableViewDataSource,NSDrawerDelegate,NSTabViewDelegate> {
@private
    NSWindow *window;
    ToolBar *toolBar;
    DetailsDataSource *detailsDataSource;
    
    NSString *searchString;

    NSArray *machDefaults;
    NSArray *latestMacOsDefaults;
    NSArray *latestMacOsOtherDefaults;

	NSMutableDictionary	 *sysDict;
	NSMutableDictionary	 *usrDict;
	NSMutableDictionary	 *osxDict;
	NSMutableDictionary	 *machDict;
	NSMutableDictionary	 *othersDict;   
    
	NSMutableDictionary	 *sysDictSearch;
	NSMutableDictionary	 *usrDictSearch;
	NSMutableDictionary	 *osxDictSearch;
	NSMutableDictionary	 *machDictSearch;
	NSMutableDictionary	 *othersDictSearch;    
    
	IBOutlet NSTabView *mainTab;
	IBOutlet NSTabView *drawerTab;    
	IBOutlet NSTableView *sysTable;
	IBOutlet NSTableView *usrTable;
	IBOutlet NSTableView *osxTable;
	IBOutlet NSTableView *machTable;
	IBOutlet NSTableView *othersTable;	
    
    IBOutlet NSWindow *windowMsg;
    IBOutlet NSTextField *textMsg;
    IBOutlet NSProgressIndicator *progMsg;
	
    IBOutlet NSDrawer *drawInf;
    
    IBOutlet NSButton *toggleButton;
    IBOutlet NSButton *stopButton;
    IBOutlet NSButton *removeButton;  
    IBOutlet NSButton *dismissButton;   
    IBOutlet NSOutlineView *detailsOutline;
         
}

@property (assign) IBOutlet NSWindow *window;

@property (retain) NSString *searchString;

-(void)discloseInfo;
-(NSDictionary*)dictForSelectedRowInTable:(NSTableView *)theTableView;
- (NSMenu *)menuForClickedRow:(NSInteger)row inTable:(NSTableView *)theTableView;
-(void)revealInFinder:(NSMenuItem*)sender;

-(void)addTableColumn:(NSString*)name toTable:(NSTableView*)table;
-(NSDictionary*)sortData:(NSDictionary*)dict with:(NSArray*)tableSort;
-(void)reloadTables;

-(void)refresh:(BOOL)all;
-(void)getServices;
-(void)getOthers;
-(void)addListingAt:(NSString*)path type:(NSString*)type to:(NSMutableDictionary*)to alsoInHome:(BOOL)home;
- (NSDictionary*)fileDetails:(NSString *)name path:(NSString *)path executable:(NSString *)executable disabledList:(NSArray*)disabledList loadedList:(NSArray*)loadedList;
-(NSDate*)fileCDate:(NSString *)file;
-(void)setRunningStatusFor:(NSMutableDictionary*)target processList:(NSArray*)processList;
-(NSArray*)getLaunchdDisabledList;
-(NSArray*)getLaunchdLoadedList;

- (void)showMsg:(NSString *)msg;
- (void)showNotice:(NSString *)msg;
- (void)closeMsg;
-(IBAction)dismiss:(id)sender;

-(IBAction)disableService:(id)sender;
-(IBAction)stopProcess:(id)sender;
-(IBAction)removeService:(id)sender;
-(void)terminatePid:(pid_t)pid;
- (void)removeLoginItem:(NSString*)appName;
- (void)trashPath:(NSString*)path;
-(void)disableServiceNamed:(NSString*)name;

- (NSDictionary*)runningDaemonInfo:(NSString*)appName;
- (NSDictionary *)infoForPID:(pid_t)pid;
- (NSArray*)getCarbonProcessList;
- (NSArray*)getBSDProcessList;
- (NSString*)getNameForUID:(int)uid;
-(BOOL)userIsRoot:(NSString*)username;

-(NSString*)execTask:(NSString*)launch args:(NSArray*)args;
- (BOOL)matchStr:(NSString *)needle haystack:(NSString *)haystack;
-(NSDictionary*)filterDict:(NSDictionary*)source forString:(NSString*)query;
-(void)reorderDict:(NSMutableDictionary*)dict withGapAt:(NSInteger)index;
-(NSArray*)mergeArraysFilteringDuplicates:(NSArray*)one with:(NSArray*)two;
-(NSDictionary*)dictionaryFromArray:(NSArray*)arr;

@end

@interface NSColor (StringOverrides)
+(NSArray *)controlAlternatingRowBackgroundColors;
@end
