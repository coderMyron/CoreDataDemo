//
//  AppDelegate.m
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import "AppDelegate.h"

typedef void (^RootContextSave)(void);

@interface AppDelegate ()


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"CoreDataDemo"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

//--------------------------
// 获取PSC实例对象
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // 创建托管对象模型，并指明加载Company模型文件
    NSURL *modelPath = [[NSBundle mainBundle] URLForResource:@"CoreDataDemo" withExtension:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelPath];

    // 创建PSC对象，并将托管对象模型当做参数传入，其他MOC都是用这一个PSC。
    NSPersistentStoreCoordinator *PSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    // 根据指定的路径，创建并关联本地数据库
    NSString *dataPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    dataPath = [dataPath stringByAppendingFormat:@"/%@.sqlite", @"CoreDataDemo"];
    [PSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:dataPath] options:nil error:nil];

    return PSC;
}

//这是appDelegate中的backgroundContext
-(NSManagedObjectContext *)rootObjectContext {
    if (nil != _rootObjectContext) {
        return _rootObjectContext;
    }
     
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _rootObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_rootObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _rootObjectContext;
}

//这是mainContext
-(NSManagedObjectContext *)managedObjectContext {
    if (nil != _managedObjectContext) {
            return _managedObjectContext;
        }
         
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.parentContext = [self rootObjectContext];
        return _managedObjectContext;
}

//AppDelegate中saveContext方法，每次privateContext调用save方法成功之后都要call这个方法
- (void)saveContextWithWait:(BOOL)needWait
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSManagedObjectContext *rootObjectContext = [self rootObjectContext];
     
    if (nil == managedObjectContext) {
        return;
    }
    if ([managedObjectContext hasChanges]) {
        NSLog(@"Main context need to save");
        [managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            if (![managedObjectContext save:&error]) {
                NSLog(@"Save main context failed and error is %@", error);
            }
        }];
    }
     
    if (nil == rootObjectContext) {
        return;
    }
     
    RootContextSave rootContextSave = ^ {
        NSError *error = nil;
        if (![self->_rootObjectContext save:&error]) {
            NSLog(@"Save root context failed and error is %@", error);
        }
    };
     
    if ([rootObjectContext hasChanges]) {
        NSLog(@"Root context need to save");
        if (needWait) {
            [rootObjectContext performBlockAndWait:rootContextSave];
        }
        else {
            [rootObjectContext performBlock:rootContextSave];
        }
    }
}

@end
