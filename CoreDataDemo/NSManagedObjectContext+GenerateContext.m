//
//  NSManagedObjectContext+GenerateContext.m
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import "NSManagedObjectContext+GenerateContext.h"

@implementation NSManagedObjectContext (GenerateContext)

+(NSManagedObjectContext *)generatePrivateContextWithParent:(NSManagedObjectContext *)parentContext {
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = parentContext;
    return privateContext;
}

@end
