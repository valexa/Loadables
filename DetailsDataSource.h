//
//  DetailsDataSource.h
//  Loadables
//
//  Created by Vlad Alexa on 5/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DetailsDataSource : NSObject <NSOutlineViewDataSource,NSOutlineViewDelegate> {
@private
	NSDictionary *rootItems;   
    NSMutableDictionary *keysDict;
    NSMutableArray *refArray;    
}

@property (retain) NSDictionary *rootItems;

- (NSDictionary *) indexKeyedDictFromArray:(NSArray *)array;

@end
