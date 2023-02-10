# CoreDataDemo
Core Data多线程调用（增删改查）demo

# 多线程调用方式
在CoreData中MOC(NSManageObjectContext)不是线程安全的，苹果给出了自己的解决方案。
在创建的MOC中使用多线程，无论是私有队列还是主队列，都应该采用下面两种多线程的使用方式，而不是自己手动创建线程。调用下面方法后，系统内部会将任务派发到不同的队列中执行。可以在不同的线程中调用MOC的这两个方法，这个是允许的。
```
- (void)performBlock:(void (^)())block            异步执行的block，调用之后会立刻返回。
- (void)performBlockAndWait:(void (^)())block     同步执行的block，调用之后会等待这个任务完成，才会继续向下执行。
在多线程的环境下执行MOC的save方法，就是将save方法放在MOC的block体中异步执行，其他方法的调用也是一样的。
[context performBlock:^{
    [context save:nil];
}];
```
## 多线程的使用
### iOS5之前使用多个MOC
在iOS5之前实现MOC的多线程，可以创建多个MOC，多个MOC使用同一个PSC(NSPersistentStoreCoordinator)，并让多个MOC实现数据同步。通过这种方式不用担心PSC在调用过程中的线程问题，MOC在使用PSC进行save操作时，会对PSC进行加锁，等当前加锁的MOC执行完操作之后，其他MOC才能继续执行操作。
在MOC发生改变时，将其他MOC数据更新
```
// 获取PSC实例对象
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

	// 创建托管对象模型，并指明加载Company模型文件
	NSURL *modelPath = [[NSBundle mainBundle] URLForResource:@"Company" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelPath];

	// 创建PSC对象，并将托管对象模型当做参数传入，其他MOC都是用这一个PSC。
	NSPersistentStoreCoordinator *PSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	// 根据指定的路径，创建并关联本地数据库
	NSString *dataPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
	dataPath = [dataPath stringByAppendingFormat:@"/%@.sqlite", @"Company"];
	[PSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:dataPath] options:nil error:nil];

	return PSC;
}

// 初始化用于本地存储的所有MOC
- (void)createManagedObjectContext {

	// 创建PSC实例对象，其他MOC都用这一个PSC。
	NSPersistentStoreCoordinator *PSC = self.persistentStoreCoordinator;

	// 创建主队列MOC，用于执行UI操作
	NSManagedObjectContext *mainMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	mainMOC.persistentStoreCoordinator = PSC;

	// 创建私有队列MOC，用于执行其他耗时操作
	NSManagedObjectContext *backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	backgroundMOC.persistentStoreCoordinator = PSC;

	// 通过监听NSManagedObjectContextDidSaveNotification通知，来获取所有MOC的改变消息
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

// MOC改变后的通知回调
- (void)contextChanged:(NSNotification *)noti {
	NSManagedObjectContext *MOC = noti.object;
	// 这里需要做判断操作，判断当前改变的MOC是否我们将要做同步的MOC，如果就是当前MOC自己做的改变，那就不需要再同步自己了。
	// 由于项目中可能存在多个PSC，所以下面还需要判断PSC是否当前操作的PSC，如果不是当前PSC则不需要同步，不要去同步其他本地存储的数据。
	[MOC performBlock:^{
    	// 直接调用系统提供的同步API，系统内部会完成同步的实现细节。
    	[MOC mergeChangesFromContextDidSaveNotification:noti];
	}];
}
```
### iOS5之后使用多个MOC
在iOS5之后，MOC可以设置parentContext，一个parentContext可以拥有多个ChildContext。在ChildContext执行save操作后，会将操作push到parentContext，由parentContext去完成真正的save操作，而ChildContext所有的改变都会被parentContext所知晓，这解决了之前MOC手动同步数据的问题。
需要注意的是，在ChildContext调用save方法之后，此时并没有将数据写入存储区，还需要调用parentContext的save方法。因为ChildContext并不拥有PSC，ChildContext也不需要设置PSC，所以需要parentContext调用PSC来执行真正的save操作。也就是只有拥有PSC的MOC执行save操作后，才是真正的执行了写入存储区的操作。
```
- (void)createManagedObjectContext {
	// 创建PSC实例对象，还是用上面Demo的实例化代码
	NSPersistentStoreCoordinator *PSC = self.persistentStoreCoordinator;

	// 创建主队列MOC，用于执行UI操作
	NSManagedObjectContext *mainMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	mainMOC.persistentStoreCoordinator = PSC;

	// 创建私有队列MOC，用于执行其他耗时操作，backgroundMOC并不需要设置PSC
	NSManagedObjectContext *backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	backgroundMOC.parentContext = mainMOC;

	// 私有队列的MOC和主队列的MOC，在执行save操作时，都应该调用performBlock:方法，在自己的队列中执行save操作。
	// 私有队列的MOC执行完自己的save操作后，还调用了主队列MOC的save方法，来完成真正的持久化操作，否则不能持久化到本地
	[backgroundMOC performBlock:^{
    		[backgroundMOC save:nil];
    
    		[mainMOC performBlock:^{
        		[mainMOC save:nil];
    		}];
	}];
}
```
demo是用到三个MOC,persistentStoreCoordinator<-backgroundContext<-mainContext<-privateContext
这种设计是第一种的改进设计，也是上述的老外博主推荐的一种设计方式。它总共有三个Context，一是连接persistentStoreCoordinator也是最底层的backgroundContext，二是UI线程的mainContext，三是子线程的privateContext，他们的关系是privateContext.parentContext = mainContext, mainContext.parentContext = backgroundContext。
## 线程安全
托管对象是不能直接传递到其他MOC的线程的，但是可以通过获取NSManagedObject的NSManagedObjectID对象，在其他MOC中通过NSManagedObjectID对象，从持久化存储区中获取NSManagedObject对象，这样就是允许的。NSManagedObjectID是线程安全，并且可以跨线程使用的。
可以通过MOC获取NSManagedObjectID对应的NSManagedObject对象
```
NSManagedObject *object = [context objectRegisteredForID:objectID];
NSManagedObject *object = [context objectWithID:objectID];
```
通过NSManagedObject对象的objectID属性，获取NSManagedObjectID类型的objectID对象。
```
NSManagedObjectID *objectID = object.objectID;
```

