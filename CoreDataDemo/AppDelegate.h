//
//  AppDelegate.h
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

@property (nonatomic, strong) NSManagedObjectContext *rootObjectContext;//backgroundContext
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;//mainContext

- (void)saveContextWithWait:(BOOL)needWait;

- (void)saveContext;


@end

