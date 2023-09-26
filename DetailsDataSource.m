//
//  DetailsDataSource.m
//  Loadables
//
//  Created by Vlad Alexa on 5/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailsDataSource.h"


@implementation DetailsDataSource

@synthesize rootItems;

- (id)init
{
    self = [super init];
    if (self) {
        keysDict = [[NSMutableDictionary alloc] init];
        refArray = [[NSMutableArray alloc] init];        
    }
    
    return self;
}

- (void)dealloc
{
    [refArray release];
	[rootItems release];
	[keysDict release];    
    [super dealloc];
}

#pragma mark tools

- (NSDictionary*)indexKeyedDictFromArray:(NSArray *)array{
    int index = 0;    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:1];
    for (id object in array) {
        [ret setObject:object forKey:[NSString stringWithFormat:@"%i",index]];
        index++;
    }    
    return ret; 
}

- (id)itemAtIndex:(NSInteger)index inSortedDict:(NSDictionary *)dict{
    NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSString *key = [sortedKeys objectAtIndex:index];
    id item = [dict objectForKey:key];  
    [refArray addObject:item];
    NSString *ret = [NSString stringWithFormat:@"%i",[refArray count]-1];
    [keysDict setObject:key forKey:ret];       
    if ([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]]) {
        return item;        //has children, will get the label by doing opposite lookup (refArray indexOfObject)
    }else{
        return ret;         //last child
    }
    return nil;
}

#pragma  mark NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) {        
        return YES; //item is nil when the outline view wants to inquire for root level items
    }
    
    if ([item isKindOfClass:[NSArray class]]) {
        return YES;
    }
    
    if ([item isKindOfClass:[NSDictionary class]]) {           
        return YES;
    } 
    
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{    
    
    if (item == nil) {
        [keysDict removeAllObjects];
        [refArray removeAllObjects]; 
        return 1;  //item is nil when the outline view wants to inquire for root level items
    }  
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        return [item count];
    }
    
    if ([item isKindOfClass:[NSArray class]]) {
        return [item count];
    }         
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    
	if (item == nil) {
        return rootItems; //item is nil when the outline view wants to inquire for root level items
    }
    
    if ([item isKindOfClass:[NSArray class]]) {
        NSDictionary *dict = [self indexKeyedDictFromArray:item];
        return [self itemAtIndex:index inSortedDict:dict];      
    }
    
    if ([item isKindOfClass:[NSDictionary class]])  {
        return [self itemAtIndex:index inSortedDict:item];
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{    
       
    if (item == rootItems) {
        //no label or value for root key
        return nil;
    }
    
    NSString *ident = [tableColumn identifier];      
        
    if ([ident isEqualToString:@"_one"]) {
        if ([item isKindOfClass:[NSString class]]) {
            return [keysDict objectForKey:item];
        }else{
            return [keysDict objectForKey:[NSString stringWithFormat:@"%i",[refArray indexOfObject:item]]];
        }        
    } 
    
    if ([ident isEqualToString:@"_two"]) {
        id object = nil;
        if ([item isKindOfClass:[NSString class]]) {
            object = [refArray objectAtIndex:[item intValue]];        
        }else{
            object = item;
        }
        if ([object isKindOfClass:[NSData class]]) {
            if ([object length] < 900) {
                return [[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] autorelease];                            
            }else{
                return [NSString stringWithFormat:@"[-%lu bytes of data-]",[object length]];                
            }
        }else if ([object isKindOfClass:[NSArray class]]) {
            //return [NSString stringWithFormat:@"[-array %lu-]",[object count]];
        }else if ([object isKindOfClass:[NSDictionary class]]) {      
            //return [NSString stringWithFormat:@"[-dict %lu-]",[object count]];
        }else if ([object isKindOfClass:[NSNumber class]]) {
            if ([object intValue] == 0) return @"NO";
            if ([object intValue] == 1) return @"YES";             
            return [object description];
        }else if ([object isKindOfClass:[NSData class]]) {  
            return [object descriptionWithCalendarFormat:@"%Y/%m/%d %H:%M:%S " timeZone:nil locale:nil];
        } else {
            return [object description];                
        }
    }  
    
    return nil;
}

@end
