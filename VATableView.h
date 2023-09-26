//
//  VATableView.h
//  Loadables
//
//  Created by Vlad Alexa on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VATableViewDelegate;

@interface VATableView : NSTableView {

}

@property (nullable, weak) id <NSTableViewDelegate> delegate;

@end

@protocol VATableViewDelegate<NSTableViewDelegate>

@required

- (NSMenu *_Nullable)menuForClickedRow:(NSInteger)row inTable:(NSTableView *_Nullable)theTableView;

@end
