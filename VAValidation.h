//
//  VAValidation.h
//  LaunchBoard
//
//  Created by Vlad Alexa on 1/11/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VAValidation : NSObject {
	
}

+(int)v;
+(int)a;
+(int)v:(NSBundle*)b;
+(int)a:(NSBundle*)b;
+(NSArray*)certificatesFor:(NSString*)path;

@end
