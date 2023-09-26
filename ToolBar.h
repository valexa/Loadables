//
//  ToolBar.h
//  DiskFailure
//
//  Created by Vlad Alexa on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LoadablesAppDelegate;

@interface ToolBar : NSObject <NSToolbarDelegate,NSTextFieldDelegate> {
    NSToolbar *theBar;
@private
    NSMutableDictionary *items;	 
    LoadablesAppDelegate *delegate;
}

@property (assign) LoadablesAppDelegate *delegate;

@property (retain) NSToolbar *theBar;

- (NSToolbarItem *) configureToolbarItem: (NSDictionary *)optionsDict;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)thetoolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)thetoolbar;

- (void)runAscript:(NSString*)script;
-(BOOL)userIsRoot:(NSString*)username;

@end
