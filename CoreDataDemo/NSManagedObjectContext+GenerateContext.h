//
//  NSManagedObjectContext+GenerateContext.h
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObjectContext (GenerateContext)

+(NSManagedObjectContext *)generatePrivateContextWithParent:(NSManagedObjectContext *)parentContext;

@end

NS_ASSUME_NONNULL_END
