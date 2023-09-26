//
//  main.m
//  Loadables
//
//  Created by Vlad Alexa on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VAValidation.h"

int main(int argc, char *argv[])
{
    
    @autoreleasepool {
        //prevent crash with deny file-write-data /private/var/db/mds/system/mds.lock
        if (![NSUserName() isEqualToString:@"root"]){
            int v = [VAValidation v];		
            int a = [VAValidation a];
            if (v+a != 0) return(v+a);
        }          
    }    
    
    return NSApplicationMain(argc,  (const char **) argv);    
    
}
