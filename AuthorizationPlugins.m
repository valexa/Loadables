//
//  AuthorizationPlugins.m
//  Loadables
//
//  Created by Vlad Alexa on 5/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AuthorizationPlugins.h"

#include <CoreServices/CoreServices.h>
#include <Security/Security.h>

@implementation AuthorizationPlugins

+(NSArray*)listMechanisms
{
    // lists "mechanisms" array of the "system.login.console" right definition.     
    OSStatus                err;
    CFDictionaryRef         rightDict;
    CFStringRef             authClass;
    CFArrayRef              authMechanisms;
    static const char *     kConsoleLoginRightName = "system.login.console";
    
    rightDict = NULL;    
    
    // Get the rights definition  
    err = AuthorizationRightGet(kConsoleLoginRightName, &rightDict);
    
    //check that the class is "evaluate-mechanisms".  
    if (err == noErr) {
        authClass = (CFStringRef) CFDictionaryGetValue(rightDict, CFSTR("class"));
        if ( (authClass == NULL) || (CFGetTypeID(authClass) != CFStringGetTypeID()) ) {
            err = coreFoundationUnknownErr;
        } else if ( ! CFEqual(authClass, CFSTR("evaluate-mechanisms")) ) {
            err = errAuthorizationInternal;
        }
    }
    
    // Get the mechanisms array    
    if (err == noErr) {
        authMechanisms = (CFArrayRef) CFDictionaryGetValue(rightDict,CFSTR("mechanisms"));
        if ( (authMechanisms == NULL) || (CFGetTypeID(authMechanisms) != CFArrayGetTypeID()) ) {
            err = coreFoundationUnknownErr;
        }
    }
    if ( err == noErr) {
        return [NSArray arrayWithArray:(NSArray*)authMechanisms];
    }
    
    // Clean up.
    if (rightDict != NULL) {
        CFRelease(rightDict);
    }
    
    if (err != noErr){
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:(NSInteger)err userInfo:nil];
        NSLog(@"ListMechanisms error: %@",[error description]);        
    }    
    
    return NULL;
}

@end
