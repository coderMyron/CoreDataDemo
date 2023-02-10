//
//  AppDelegate.h
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

//persistentStoreCoordinator<-backgroundContext<-mainContext<-privateContext
@property (readonly, strong) NSPersistentContainer *persistentContainer;

@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;

- (void)saveContextWithWait:(BOOL)needWait;

- (void)saveContext;


@end

